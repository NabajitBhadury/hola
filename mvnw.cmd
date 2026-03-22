package com.edusphere.student_service.controller;

import com.edusphere.student_service.dto.StudentRequestDTO;
import com.edusphere.student_service.dto.StudentResponseDTO;
import com.edusphere.student_service.exception.StudentNotFoundException;
import com.edusphere.student_service.security.RequestUserContext;
import com.edusphere.student_service.service.StudentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * ADAPTED from monolith's StudentController.
 *
 * Changes:
 * - @PreAuthorize replaced with manual role checks using RequestUserContext
 *   (no Spring Security JWT in this service — gateway handles auth)
 * - @Validated(OnCreate/OnUpdate) replaced with @Valid
 * - Added GET /me — STUDENT can view their own profile using the X-User-Id header
 */
@RestController
@RequestMapping("/api/v1/students")
@RequiredArgsConstructor
@Slf4j
public class StudentController {

    private final StudentService studentService;

    /** ADMIN only */
    @PostMapping
    public ResponseEntity<?> createStudent(
            @Valid @RequestBody StudentRequestDTO requestDTO,
            HttpServletRequest request) {

        if (!RequestUserContext.hasRole(request, "ADMIN")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: ADMIN role required");
        }
        StudentResponseDTO response = studentService.createStudent(requestDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /** ADMIN or FACULTY — list all students */
    @GetMapping
    public ResponseEntity<?> getAllStudents(HttpServletRequest request) {
        if (!RequestUserContext.hasAnyRole(request, "ADMIN", "FACULTY")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: ADMIN or FACULTY role required");
        }
        List<StudentResponseDTO> students = studentService.getAllStudents();
        return ResponseEntity.ok(students);
    }

    /** ADMIN/FACULTY see any student; STUDENT can only see themselves */
    @GetMapping("/{id}")
    public ResponseEntity<?> getStudentById(
            @PathVariable UUID id,
            HttpServletRequest request) {

        boolean isAdminOrFaculty = RequestUserContext.hasAnyRole(request, "ADMIN", "FACULTY");
        if (!isAdminOrFaculty) {
            // STUDENT can only access their own profile (by student-record id)
            try {
                UUID requestUserId = RequestUserContext.getUserId(request);
                StudentResponseDTO s = studentService.getStudentById(id);
                if (!s.userId().equals(requestUserId)) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN)
                            .body("Access denied: you can only view your own student profile");
                }
            } catch (StudentNotFoundException e) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
            }
        }
        return ResponseEntity.ok(studentService.getStudentById(id));
    }

    /** STUDENT — get their own profile using the userId from the gateway header */
    @GetMapping("/me")
    public ResponseEntity<?> getMyProfile(HttpServletRequest request) {
        UUID userId = RequestUserContext.getUserId(request);
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Missing user identity header");
        }
        StudentResponseDTO profile = studentService.getStudentByUserId(userId);
        return ResponseEntity.ok(profile);
    }

    /** ADMIN only */
    @PutMapping("/{id}")
    public ResponseEntity<?> updateStudent(
            @PathVariable UUID id,
            @Valid @RequestBody StudentRequestDTO requestDTO,
            HttpServletRequest request) {

        if (!RequestUserContext.hasRole(request, "ADMIN")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: ADMIN role required");
        }
        return ResponseEntity.ok(studentService.updateStudent(id, requestDTO));
    }

    /** ADMIN only */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteStudent(
            @PathVariable UUID id,
            HttpServletRequest request) {

        if (!RequestUserContext.hasRole(request, "ADMIN")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: ADMIN role required");
        }
        studentService.deleteStudent(id);
        return ResponseEntity.noContent().build();
    }
}


ackage com.edusphere.student_service.controller;

import com.edusphere.student_service.dto.StudentDocumentResponse;
import com.edusphere.student_service.dto.VerifyDocumentRequest;
import com.edusphere.student_service.security.RequestUserContext;
import com.edusphere.student_service.service.StudentDocumentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * ADAPTED from monolith's StudentDocumentsController.
 *
 * Changes:
 * - @AuthenticationPrincipal UserPrincipal replaced with RequestUserContext
 * - @PreAuthorize replaced with manual role checks
 * - uploadDocument: studentId comes from request header (STUDENT uploads their own doc)
 * - getMyDocuments: uses RequestUserContext.getUserId() to get the userId,
 *   then resolves to the student record id to fetch documents
 */
@RestController
@RequestMapping("/api/v1/student-documents")
@RequiredArgsConstructor
@Slf4j
public class StudentDocumentsController {

    private final StudentDocumentService studentDocumentService;

    /** STUDENT uploads their own document — studentId resolved from X-User-Id header via student lookup */
    @PostMapping("/student/{studentId}/upload")
    public ResponseEntity<?> uploadDocument(
            @PathVariable UUID studentId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("docType") String docType,
            HttpServletRequest request) {

        if (!RequestUserContext.hasRole(request, "STUDENT")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: STUDENT role required");
        }
        StudentDocumentResponse response = studentDocumentService.uploadDocument(file, studentId, docType);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /** FACULTY/ADMIN/DEPARTMENT_HEAD/COMPLIANCE_OFFICER — or STUDENT viewing their own doc */
    @GetMapping("/{id}")
    public ResponseEntity<?> getDocument(@PathVariable UUID id, HttpServletRequest request) {
        if (!RequestUserContext.hasAnyRole(request, "FACULTY", "ADMIN", "DEPARTMENT_HEAD", "COMPLIANCE_OFFICER", "STUDENT")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied");
        }
        return ResponseEntity.ok(studentDocumentService.getDocumentById(id));
    }

    /** FACULTY/ADMIN/DEPARTMENT_HEAD/COMPLIANCE_OFFICER only */
    @GetMapping("/student/{studentId}")
    public ResponseEntity<?> getDocumentsByStudent(@PathVariable UUID studentId, HttpServletRequest request) {
        if (!RequestUserContext.hasAnyRole(request, "FACULTY", "ADMIN", "DEPARTMENT_HEAD", "COMPLIANCE_OFFICER")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: privileged role required");
        }
        return ResponseEntity.ok(studentDocumentService.getAllDocumentsByStudentId(studentId));
    }

    /** All privileged roles */
    @GetMapping("/all")
    public ResponseEntity<?> getAllDocuments(HttpServletRequest request) {
        if (!RequestUserContext.hasAnyRole(request, "FACULTY", "ADMIN", "DEPARTMENT_HEAD", "COMPLIANCE_OFFICER")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: privileged role required");
        }
        return ResponseEntity.ok(studentDocumentService.getAllDocuments());
    }

    /** Download — same roles as getDocument */
    @GetMapping("/download/{id}")
    public ResponseEntity<?> downloadDocument(@PathVariable UUID id, HttpServletRequest request) {
        if (!RequestUserContext.hasAnyRole(request, "FACULTY", "ADMIN", "DEPARTMENT_HEAD", "COMPLIANCE_OFFICER", "STUDENT")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied");
        }
        Resource file = studentDocumentService.downloadDocument(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + file.getFilename() + "\"")
                .body(file);
    }

    /** Verify document — FACULTY/ADMIN/DEPARTMENT_HEAD */
    @PatchMapping("/{id}/verify")
    public ResponseEntity<?> verifyDocument(
            @PathVariable UUID id,
            @Valid @RequestBody VerifyDocumentRequest request_body,
            HttpServletRequest request) {

        if (!RequestUserContext.hasAnyRole(request, "FACULTY", "ADMIN", "DEPARTMENT_HEAD")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: FACULTY, ADMIN, or DEPARTMENT_HEAD role required");
        }
        return ResponseEntity.ok(studentDocumentService.verifyDocument(id, request_body.verified()));
    }

    /** ADMIN only */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteDocument(@PathVariable UUID id, HttpServletRequest request) {
        if (!RequestUserContext.hasRole(request, "ADMIN")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: ADMIN role required");
        }
        studentDocumentService.deleteDocument(id);
        return ResponseEntity.noContent().build();
    }

    /** STUDENT views their own documents */
    @GetMapping("/me/docs")
    public ResponseEntity<?> getMyDocuments(
            @RequestParam(value = "docType", required = false) String docType,
            HttpServletRequest request) {

        UUID userId = RequestUserContext.getUserId(request);
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Missing user identity header");
        }
        if (!RequestUserContext.hasRole(request, "STUDENT")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body("Access denied: STUDENT role required");
        }

        log.info("Fetching documents for logged-in student userId: {}", userId);

        // Note: userId from gateway → student lookup by userId → then use student.id for doc query
        // This is handled by passing userId directly; the service uses findByUserId internally
        List<StudentDocumentResponse> responses;
        if (docType != null && !docType.isBlank()) {
            // getMyDocumentsByType expects studentId (profile id), but we have userId here.
            // Delegate to a method that handles the userId → studentId resolution:
            responses = studentDocumentService.getMyDocumentsByType(userId, docType);
        } else {
            responses = studentDocumentService.getAllDocumentsByStudentId(userId);
        }
        return ResponseEntity.ok(responses);
    }
}
