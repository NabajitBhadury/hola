# EduSphere Microservices Migration Guide

To convert your monolithic `edusphere` project into a true microservices architecture, you will need to create **6 new Spring Boot projects**. Along with the API Gateway you just built, you will have 7 projects in total.

Here is the exact mapping of what files and folders from the monolith need to be moved to which new microservice.

---

## 🏗️ 1. `iam-service` (Identity & Access Management)
This service acts as the central authentication authority.
- **Port:** `8081`
- **Move these Packages/Classes from `edusphere`**:
  - `config/security/` (Keep `JwtService`, `CustomUserDetailsService`, `UserPrincipal`)
  - `controllers/user/` (User login, signup, profile endpoints)
  - `services/user/` (User business logic)
  - `repositories/user/` (User database access)
  - `core/entity/user/` (User JPA entities)
  - `common/dto/user/` (User DTOs)

## 🎓 2. `student-service` (Student Success Management)
This service handles student profiles, documents, and theses.
- **Port:** `8082`
- **Move these Packages/Classes from `edusphere`**:
  - **Controllers:** `controllers/student/`, `controllers/student_document/`, `controllers/thesis/`
  - **Services:** `services/student/`, `services/student_document/`, `services/thesis/`
  - **Repositories:** `repositories/student/`, `repositories/student_document/`, `repositories/thesis/`
  - **Entities:** `core/entity/student/`, `core/entity/student_document/`, `core/entity/thesis/`
  - **DTOs:** `common/dto/student/`, `common/dto/student_document/`, `common/dto/thesis/`

## 🏫 3. `faculty-service` (Academic & Faculty Management)
This service manages professors, academic departments, workloads, and research.
- **Port:** `8083`
- **Move these Packages/Classes from `edusphere`**:
  - **Controllers:** `controllers/faculty/`, `controllers/department/`, `controllers/workLoad/`, `controllers/research_project/`
  - **Services:** `services/faculty/`, `services/department/`, `services/workLoad/`, `services/research_project/`
  - **Repositories:** `repositories/faculty/`, `repositories/department/`, `repositories/workLoad/`, `repositories/research_project/`
  - **Entities:** `core/entity/faculty/`, `core/entity/department/`, `core/entity/workLoad/`, `core/entity/research_project/`
  - **DTOs:** `common/dto/faculty/`, `common/dto/department/`, `common/dto/workLoad/`, `common/dto/research_project/`

## 📚 4. `curriculum-service` (Courses & Examinations)
This is the core academic engine managing syllabus, classes, exams, and grades.
- **Port:** `8084`
- **Move these Packages/Classes from `edusphere`**:
  - **Controllers:** `controllers/course/`, `controllers/curriculum/`, `controllers/exam/`, `controllers/grade/`
  - **Services:** `services/course/`, `services/curriculum/`, `services/exam/`, `services/grade/`
  - **Repositories:** `repositories/course/`, `repositories/curriculum/`, `repositories/exam/`, `repositories/grade/`
  - **Entities:** `core/entity/course/`, `core/entity/curriculum/`, `core/entity/exam/`, `core/entity/grade/`
  - **DTOs:** `common/dto/course/`, `common/dto/curriculum/`, `common/dto/exam/`, `common/dto/grade/`

## ⚖️ 5. `compliance-service` (Audit & Reporting)
This service tracks compliance and audit actions asynchronously.
- **Port:** `8085`
- **Move these Packages/Classes from `edusphere`**:
  - **Controllers:** `controllers/audit/`, `controllers/audit_log/`, `controllers/compliance_record/`, `controllers/report/`
  - **Services:** `services/audit/`, `services/audit_log/`, `services/compliance_record/`, `services/report/`
  - **Repositories:** `repositories/audit/`, `repositories/audit_log/`, `repositories/compliance_record/`, `repositories/report/`
  - **Entities:** `core/entity/audit/`, `core/entity/audit_log/`, `core/entity/compliance_record/`, `core/entity/report/`
  - **DTOs:** `common/dto/audit/`, `common/dto/audit_log/`, `common/dto/compliance_record/`, `common/dto/report/`
  - **Aspects:** Move any Audit-related `@Aspect` classes here (like your `@ComplianceAudit` logic).

## 🔔 6. `notification-service`
This service handles all broadcast, role-based, and individual notifications.
- **Port:** `8086`
- **Move these Packages/Classes from `edusphere`**:
  - **Controllers:** `controllers/notification/`
  - **Services:** `services/notification/`
  - **Repositories:** `repositories/notification/`
  - **Entities:** `core/entity/notification/`
  - **DTOs:** `common/dto/notification/`

---

## 🛠️ Step-by-Step Execution Plan

1. **Wait to Delete the Monolith**: DO NOT delete `edusphere` until all 6 of the above microservices are created and tested.
2. **Generate Projects**: Go to Spring Initializr (or use your IDE) and generate the 6 new Spring Boot projects mentioned above. 
3. **Add Standard Dependencies**: Add these basic dependencies to the [pom.xml](file:///Users/perfecto/code_space/test/micro/pom.xml) of *every* new microservice:
   - Spring Web
   - Spring Data JPA
   - MySQL Driver
   - Eureka Discovery Client
   - OpenFeign
   - Spring Security
4. **Copy the Code**: Physically cut-and-paste the Java packages listed in the sections above from the `edusphere` project into their new respective microservice projects. 
5. **Implement `HeaderAuthenticationFilter`**: In services #2 through #6, add the simple `HeaderAuthenticationFilter` (the code snippet provided previously) to translate the Gateway headers into the `UserPrincipal`, keeping your `@PreAuthorize` security intact.
6. **Set up application.yaml**: Set their respective `server.port` and hook them up to the Eureka Server.
7. **Refactor Database Relations**: Any cross-service entity relations (e.g., a `Student` entity that has a mapped `Department` object) must be broken. Replace object mappings with `Long departmentId` and use OpenFeign to fetch object data dynamically.
