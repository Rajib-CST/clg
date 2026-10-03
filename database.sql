-- =====================================================================
--  Online College Management and Recruitment System  -  MySQL 8
--  Run once:   mysql -u root -p < database.sql      (or run it in MySQL Workbench)
--  WARNING: the next line DROPS an existing college_db so the script can be re-run cleanly.
-- =====================================================================
DROP DATABASE IF EXISTS college_db;
CREATE DATABASE college_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE college_db;

-- ---------- login accounts (all roles) ----------
CREATE TABLE users (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('ADMIN','FACULTY','STUDENT','RECRUITER') NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_users_name UNIQUE (name),
  INDEX idx_users_role (role)
) ENGINE=InnoDB;

-- ---------- valid payment receipts (checked at student sign-up) ----------
CREATE TABLE payments (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  receipt_id   VARCHAR(40) NOT NULL,
  amount       DECIMAL(10,2) NOT NULL,
  payment_date DATE NOT NULL,
  is_used      TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT uk_payments_receipt UNIQUE (receipt_id),
  CONSTRAINT chk_payments_amount CHECK (amount > 0),
  INDEX idx_payments_lookup (receipt_id, payment_date, is_used)
) ENGINE=InnoDB;

CREATE TABLE students (
  id                   INT AUTO_INCREMENT PRIMARY KEY,
  user_id              INT NOT NULL,
  roll_no              VARCHAR(30) NOT NULL,
  email                VARCHAR(120) NOT NULL,
  dob                  DATE NOT NULL,
  department           VARCHAR(80) NOT NULL,
  receipt_id           VARCHAR(40) NOT NULL,
  payment_date         DATE NOT NULL,
  security_question    VARCHAR(200) NOT NULL,
  security_answer_hash VARCHAR(255) NOT NULL,
  CONSTRAINT uk_students_user    UNIQUE (user_id),
  CONSTRAINT uk_students_roll    UNIQUE (roll_no),
  CONSTRAINT uk_students_email   UNIQUE (email),
  CONSTRAINT uk_students_receipt UNIQUE (receipt_id),
  CONSTRAINT fk_students_user    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_students_payment FOREIGN KEY (receipt_id) REFERENCES payments(receipt_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_students_dept_roll (department, roll_no)
) ENGINE=InnoDB;

CREATE TABLE subjects (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  code       VARCHAR(20)  NOT NULL,
  name       VARCHAR(120) NOT NULL,
  department VARCHAR(80)  NOT NULL,
  semester   TINYINT UNSIGNED NOT NULL,
  CONSTRAINT uk_subjects_code UNIQUE (code),
  CONSTRAINT chk_subjects_sem CHECK (semester BETWEEN 1 AND 8),
  INDEX idx_subjects_dept (department)
) ENGINE=InnoDB;

CREATE TABLE faculty (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  user_id         INT NOT NULL,
  faculty_code    VARCHAR(30)  NOT NULL,
  department      VARCHAR(80)  NOT NULL,
  qualification   VARCHAR(150) NOT NULL,
  registration_no VARCHAR(50)  NOT NULL,
  email           VARCHAR(120) NOT NULL,
  phone           VARCHAR(20)  NOT NULL,
  joining_date    DATE NOT NULL,
  CONSTRAINT uk_faculty_user  UNIQUE (user_id),
  CONSTRAINT uk_faculty_code  UNIQUE (faculty_code),
  CONSTRAINT uk_faculty_reg   UNIQUE (registration_no),
  CONSTRAINT uk_faculty_email UNIQUE (email),
  CONSTRAINT fk_faculty_user  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE faculty_subjects (
  faculty_id INT NOT NULL,
  subject_id INT NOT NULL,
  PRIMARY KEY (faculty_id, subject_id),
  CONSTRAINT fk_fs_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(id)  ON DELETE CASCADE,
  CONSTRAINT fk_fs_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE recruiters (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  company_name VARCHAR(150) NOT NULL,
  licence_id   VARCHAR(50)  NOT NULL,
  email        VARCHAR(120) NOT NULL,
  phone        VARCHAR(20)  NOT NULL,
  CONSTRAINT uk_recruiters_user    UNIQUE (user_id),
  CONSTRAINT uk_recruiters_licence UNIQUE (licence_id),
  CONSTRAINT uk_recruiters_email   UNIQUE (email),
  CONSTRAINT fk_recruiters_user    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE jobs (
  id                      INT AUTO_INCREMENT PRIMARY KEY,
  recruiter_id            INT NOT NULL,
  job_title               VARCHAR(120) NOT NULL,
  vacancies               INT UNSIGNED NOT NULL,
  start_date              DATE NOT NULL,
  end_date                DATE NOT NULL,
  education_qualification VARCHAR(150) NOT NULL,
  salary_package          VARCHAR(80)  NOT NULL,
  location                VARCHAR(120) NOT NULL,
  description             TEXT NOT NULL,
  CONSTRAINT fk_jobs_recruiter FOREIGN KEY (recruiter_id) REFERENCES recruiters(id) ON DELETE CASCADE,
  CONSTRAINT chk_jobs_period   CHECK (end_date >= start_date),
  CONSTRAINT chk_jobs_vac      CHECK (vacancies >= 1),
  INDEX idx_jobs_period (start_date, end_date)
) ENGINE=InnoDB;

CREATE TABLE semesters_sgpa (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  semester   TINYINT UNSIGNED NOT NULL,
  sgpa       DECIMAL(4,2) NOT NULL,
  CONSTRAINT uk_sgpa UNIQUE (student_id, semester),
  CONSTRAINT chk_sgpa_range CHECK (sgpa BETWEEN 0 AND 10),
  CONSTRAINT chk_sgpa_sem   CHECK (semester BETWEEN 1 AND 8),
  CONSTRAINT fk_sgpa_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE marks (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  subject_id INT NOT NULL,
  marks      DECIMAL(5,2) NOT NULL,
  CONSTRAINT uk_marks UNIQUE (student_id, subject_id),
  CONSTRAINT chk_marks_range CHECK (marks BETWEEN 0 AND 100),
  CONSTRAINT fk_marks_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fk_marks_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE attendance (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  subject_id INT NOT NULL,
  faculty_id INT NULL,
  att_date   DATE NOT NULL,
  status     ENUM('PRESENT','ABSENT') NOT NULL,
  CONSTRAINT uk_attendance UNIQUE (student_id, subject_id, att_date),
  CONSTRAINT fk_att_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fk_att_subject FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  CONSTRAINT fk_att_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(id)  ON DELETE SET NULL,
  INDEX idx_att_subject_date (subject_id, att_date)
) ENGINE=InnoDB;

CREATE TABLE faculty_reviews (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  faculty_id INT NOT NULL,
  semester   TINYINT UNSIGNED NOT NULL,
  rating     TINYINT UNSIGNED NOT NULL,
  comment    VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_review UNIQUE (student_id, faculty_id, semester),      -- one review per faculty per semester
  CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT chk_review_sem    CHECK (semester BETWEEN 1 AND 8),
  CONSTRAINT fk_review_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fk_review_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(id)  ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE doubts (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  student_id  INT NOT NULL,
  faculty_id  INT NOT NULL,
  question    VARCHAR(1000) NOT NULL,
  answer      VARCHAR(2000) NULL,
  asked_date  DATE NOT NULL,
  answered_at DATETIME NULL,
  CONSTRAINT fk_doubts_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fk_doubts_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(id)  ON DELETE CASCADE,
  INDEX idx_doubts_student_day (student_id, asked_date),
  INDEX idx_doubts_faculty (faculty_id)
) ENGINE=InnoDB;

CREATE TABLE applications (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  student_id   INT NOT NULL,
  job_id       INT NOT NULL,
  cv_name      VARCHAR(255) NOT NULL,
  cv_file      LONGBLOB NOT NULL,                  -- the CV PDF is stored in the database
  status       ENUM('Pending','Selected','Rejected') NOT NULL DEFAULT 'Pending',
  applied_date DATE NOT NULL,
  CONSTRAINT uk_applications UNIQUE (student_id, job_id),
  CONSTRAINT fk_app_student FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  CONSTRAINT fk_app_job     FOREIGN KEY (job_id)     REFERENCES jobs(id)     ON DELETE CASCADE,
  INDEX idx_app_status (status)
) ENGINE=InnoDB;

CREATE TABLE application_documents (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  application_id INT NOT NULL,
  file_name      VARCHAR(255) NOT NULL,
  file_data      LONGBLOB NOT NULL,
  CONSTRAINT fk_appdoc_app FOREIGN KEY (application_id) REFERENCES applications(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Database-level guard for "max 3 doubts per student per day" (the DAO also checks it with a COUNT query)
DELIMITER $$
CREATE TRIGGER trg_doubts_daily_limit BEFORE INSERT ON doubts
FOR EACH ROW
BEGIN
  IF (SELECT COUNT(*) FROM doubts WHERE student_id = NEW.student_id AND asked_date = NEW.asked_date) >= 3 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Daily limit reached: you can ask at most 3 doubts per day.';
  END IF;
END$$
DELIMITER ;

-- =====================================================================
--  SEED DATA
--  Sign-in names / passwords:
--    admin / Admin@123      Dr. Rao / Faculty@123      Prof. Mehta / Faculty@123
--    TechCorp HR / Recruit@123      Demo Student / Student@123      Priya Singh / Student@123
--    Added faculty / Faculty@123    Added recruiters / Recruit@123    Added students / Student@123
--  Passwords are stored as PBKDF2 hashes; these plain-text values are for local demo sign-in only.
--  Unused receipts for testing sign-up: RCPT-2026-0003 (2026-07-12), RCPT-2026-0004 (2026-07-14), RCPT-2026-0005 (2026-07-15)
-- =====================================================================
INSERT INTO users (id, name, password_hash, role) VALUES
 (1, 'admin',        '65536:3mOHhZWrEuD99mVw4ZO0Aw==:MKeLtrXZafmdZdxIBj9c5Zmq0LjLUBkjlQwRCcPJsWY=', 'ADMIN'),
 (2, 'Dr. Rao',      '65536:TCHBH2eVXMlo+m6X1b3gTA==:vQtEDV2J3GiKhJtBwWP9BvWdF8z1uQ7FUgfn3sPLv0A=',   'FACULTY'),
 (3, 'Prof. Mehta',  '65536:TCHBH2eVXMlo+m6X1b3gTA==:vQtEDV2J3GiKhJtBwWP9BvWdF8z1uQ7FUgfn3sPLv0A=',   'FACULTY'),
 (4, 'TechCorp HR',  '65536:o6aJpb4PWhYRqPg5PhHLEQ==:9p24VQjZUeL5IeqNnxXUPWPRc2JvXENmU8fIUv+O/PE=',   'RECRUITER'),
 (5, 'Demo Student', '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=',   'STUDENT'),
 (6, 'Priya Singh',  '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=',   'STUDENT'),
 (7, 'Ananya Iyer',       '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (8, 'Rahul Verma',       '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (9, 'Kavya Nair',        '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (10, 'Arjun Das',        '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (11, 'Sneha Kulkarni',   '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (12, 'Rohan Shah',       '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (13, 'Meera Joshi',      '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (14, 'Vikram Patel',     '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (15, 'Aditi Rao',        '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (16, 'Karan Malhotra',   '65536:+UYZThnKNSBwzRGkKVBOew==:DkjA5AKHn8egNoNpzyeZ8CDGrgKFp1SJ6SxMZcpInvY=', 'STUDENT'),
 (17, 'Prof. Banerjee',   '65536:TCHBH2eVXMlo+m6X1b3gTA==:vQtEDV2J3GiKhJtBwWP9BvWdF8z1uQ7FUgfn3sPLv0A=', 'FACULTY'),
 (18, 'Prof. Fernandes',  '65536:TCHBH2eVXMlo+m6X1b3gTA==:vQtEDV2J3GiKhJtBwWP9BvWdF8z1uQ7FUgfn3sPLv0A=', 'FACULTY'),
 (19, 'Prof. Kapoor',     '65536:TCHBH2eVXMlo+m6X1b3gTA==:vQtEDV2J3GiKhJtBwWP9BvWdF8z1uQ7FUgfn3sPLv0A=', 'FACULTY'),
 (20, 'Prof. Reddy',      '65536:TCHBH2eVXMlo+m6X1b3gTA==:vQtEDV2J3GiKhJtBwWP9BvWdF8z1uQ7FUgfn3sPLv0A=', 'FACULTY'),
 (21, 'GreenTech HR',     '65536:o6aJpb4PWhYRqPg5PhHLEQ==:9p24VQjZUeL5IeqNnxXUPWPRc2JvXENmU8fIUv+O/PE=', 'RECRUITER'),
 (22, 'Northstar HR',     '65536:o6aJpb4PWhYRqPg5PhHLEQ==:9p24VQjZUeL5IeqNnxXUPWPRc2JvXENmU8fIUv+O/PE=', 'RECRUITER');

INSERT INTO payments (receipt_id, amount, payment_date, is_used) VALUES
 ('RCPT-2026-0001', 45000.00, '2026-07-10', 1),
 ('RCPT-2026-0002', 45000.00, '2026-07-11', 1),
 ('RCPT-2026-0003', 45000.00, '2026-07-12', 0),
 ('RCPT-2026-0004', 45000.00, '2026-07-14', 0),
 ('RCPT-2026-0005', 45000.00, '2026-07-15', 0),
 ('RCPT-2026-0006', 45000.00, '2026-07-16', 1),
 ('RCPT-2026-0007', 45000.00, '2026-07-17', 1),
 ('RCPT-2026-0008', 45000.00, '2026-07-18', 1),
 ('RCPT-2026-0009', 45000.00, '2026-07-19', 1),
 ('RCPT-2026-0010', 45000.00, '2026-07-20', 1),
 ('RCPT-2026-0011', 45000.00, '2026-07-21', 1),
 ('RCPT-2026-0012', 45000.00, '2026-07-22', 1),
 ('RCPT-2026-0013', 45000.00, '2026-07-23', 1),
 ('RCPT-2026-0014', 45000.00, '2026-07-24', 1),
 ('RCPT-2026-0015', 45000.00, '2026-07-25', 1);

INSERT INTO students (id, user_id, roll_no, email, dob, department, receipt_id, payment_date, security_question, security_answer_hash) VALUES
 (1, 5, 'CS2026001', 'demo.student@example.com', '2005-04-12', 'Computer Science', 'RCPT-2026-0001', '2026-07-10', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (2, 6, 'CS2026002', 'priya.singh@example.com',  '2005-09-03', 'Computer Science', 'RCPT-2026-0002', '2026-07-11', 'Which tree grew outside my house?', '65536:h+3jM8m2f0GBagrY38ocDQ==:8u2W3yk9ZQxgYs+GdjW8E70u43fgAuI+h3ubuFU+rYI='),
 (3, 7, 'CS2026003', 'ananya.iyer@example.com', '2005-01-19', 'Computer Science', 'RCPT-2026-0006', '2026-07-16', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (4, 8, 'CS2026004', 'rahul.verma@example.com', '2004-11-08', 'Computer Science', 'RCPT-2026-0007', '2026-07-17', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (5, 9, 'EC2026001', 'kavya.nair@example.com', '2005-02-27', 'Electronics', 'RCPT-2026-0008', '2026-07-18', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (6, 10, 'EC2026002', 'arjun.das@example.com', '2004-08-16', 'Electronics', 'RCPT-2026-0009', '2026-07-19', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (7, 11, 'EC2026003', 'sneha.kulkarni@example.com', '2005-05-04', 'Electronics', 'RCPT-2026-0010', '2026-07-20', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (8, 12, 'EC2026004', 'rohan.shah@example.com', '2004-12-21', 'Electronics', 'RCPT-2026-0011', '2026-07-21', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (9, 13, 'ME2026001', 'meera.joshi@example.com', '2005-03-13', 'Mechanical Engineering', 'RCPT-2026-0012', '2026-07-22', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (10, 14, 'ME2026002', 'vikram.patel@example.com', '2004-10-02', 'Mechanical Engineering', 'RCPT-2026-0013', '2026-07-23', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (11, 15, 'ME2026003', 'aditi.rao@example.com', '2005-06-29', 'Mechanical Engineering', 'RCPT-2026-0014', '2026-07-24', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw='),
 (12, 16, 'ME2026004', 'karan.malhotra@example.com', '2004-07-11', 'Mechanical Engineering', 'RCPT-2026-0015', '2026-07-25', 'What is my favourite colour?', '65536:yveBgTC25gYakkTEWkArMA==:fMVXo1yaY1g6EnFT+uwP0uzY6lOA+nvKt+xm0WonCcw=');
-- Security answers: Demo Student = blue, Priya Singh = maple; added students = blue.

INSERT INTO subjects (id, code, name, department, semester) VALUES
 (1, 'CS301', 'Data Structures and Algorithms', 'Computer Science', 3),
 (2, 'CS302', 'Advanced Java Programming',      'Computer Science', 3),
 (3, 'CS303', 'Database Management Systems',    'Computer Science', 3),
 (4, 'EC201', 'Digital Electronics',            'Electronics',      2),
 (5, 'CS304', 'Computer Networks',              'Computer Science', 4),
 (6, 'EC202', 'Signals and Systems',            'Electronics',      3),
 (7, 'EC203', 'Microprocessors',                'Electronics',      4),
 (8, 'EC204', 'Communication Systems',          'Electronics',      4),
 (9, 'ME101', 'Engineering Mechanics',          'Mechanical Engineering', 1),
 (10, 'ME102', 'Thermodynamics',                'Mechanical Engineering', 2),
 (11, 'ME103', 'Manufacturing Processes',       'Mechanical Engineering', 3),
 (12, 'ME104', 'Machine Design',                'Mechanical Engineering', 4);

INSERT INTO faculty (id, user_id, faculty_code, department, qualification, registration_no, email, phone, joining_date) VALUES
 (1, 2, 'FAC001', 'Computer Science', 'M.Tech, PhD (Computer Science)', 'PHD-CS-1021', 'rao@example.com',   '9876543210', '2018-06-15'),
 (2, 3, 'FAC002', 'Computer Science', 'M.Tech (Software Engineering)',  'MS-CS-2210',  'mehta@example.com', '9876501234', '2020-01-20'),
 (3, 17, 'FAC003', 'Electronics', 'M.Tech, PhD (Electronics)', 'PHD-EC-3102', 'banerjee@example.com', '9876501003', '2019-07-01'),
 (4, 18, 'FAC004', 'Electronics', 'M.Tech (Communication Systems)', 'MS-EC-4418', 'fernandes@example.com', '9876501004', '2021-02-15'),
 (5, 19, 'FAC005', 'Mechanical Engineering', 'M.Tech, PhD (Mechanical Engineering)', 'PHD-ME-5509', 'kapoor@example.com', '9876501005', '2017-08-10'),
 (6, 20, 'FAC006', 'Mechanical Engineering', 'M.Tech (Thermal Engineering)', 'MS-ME-6620', 'reddy@example.com', '9876501006', '2022-01-05');

INSERT INTO faculty_subjects (faculty_id, subject_id) VALUES
 (1, 1), (1, 2), (2, 3), (2, 5),
 (3, 4), (3, 6), (4, 7), (4, 8),
 (5, 9), (5, 10), (6, 11), (6, 12);

INSERT INTO recruiters (id, user_id, company_name, licence_id, email, phone) VALUES
 (1, 4, 'TechCorp Solutions', 'LIC-TC-7788', 'hr@techcorp.example', '9123456780'),
 (2, 21, 'GreenTech Innovations', 'LIC-GT-8821', 'careers@greentech.example', '9123456781'),
 (3, 22, 'Northstar Manufacturing', 'LIC-NS-9942', 'jobs@northstar.example', '9123456782');

INSERT INTO jobs (id, recruiter_id, job_title, vacancies, start_date, end_date, education_qualification, salary_package, location, description) VALUES
 (1, 1, 'Junior Java Developer', 5, '2026-09-01', '2026-12-31', 'B.E / B.Tech (CS or IT)', '6 LPA', 'Bengaluru',
  'Build and maintain Java servlet and JDBC based web applications. Knowledge of data structures and SQL expected.'),
 (2, 1, 'QA Trainee', 3, '2026-09-15', '2027-01-15', 'Any graduate', '4 LPA', 'Pune',
  'Write and run test cases for web applications and report defects.'),
 (3, 2, 'Embedded Systems Trainee', 4, '2026-10-15', '2027-02-15', 'B.E / B.Tech (Electronics)', '5 LPA', 'Hyderabad',
  'Assist with embedded software testing and microcontroller-based product development.'),
 (4, 3, 'Graduate Mechanical Engineer', 6, '2026-10-20', '2027-03-31', 'B.E / B.Tech (Mechanical)', '5.5 LPA', 'Chennai',
  'Support manufacturing operations, product design, and quality improvement projects.');

INSERT INTO semesters_sgpa (student_id, semester, sgpa) VALUES (1, 1, 8.40), (1, 2, 8.75), (2, 1, 7.90);
INSERT INTO marks (student_id, subject_id, marks) VALUES (1, 1, 88), (1, 2, 92), (2, 1, 76);

INSERT INTO attendance (student_id, subject_id, faculty_id, att_date, status) VALUES
 (1, 1, 1, '2026-09-21', 'PRESENT'), (1, 1, 1, '2026-09-22', 'PRESENT'), (1, 1, 1, '2026-09-23', 'ABSENT'), (1, 1, 1, '2026-09-24', 'PRESENT'),
 (1, 2, 1, '2026-09-21', 'PRESENT'), (1, 2, 1, '2026-09-23', 'PRESENT'),
 (2, 1, 1, '2026-09-21', 'PRESENT'), (2, 1, 1, '2026-09-22', 'ABSENT'), (2, 1, 1, '2026-09-23', 'PRESENT'), (2, 1, 1, '2026-09-24', 'PRESENT');

INSERT INTO faculty_reviews (student_id, faculty_id, semester, rating, comment) VALUES (1, 1, 2, 5, 'Clear explanations and great examples.');

INSERT INTO doubts (student_id, faculty_id, question, answer, asked_date, answered_at) VALUES
 (1, 1, 'What is the difference between ArrayList and LinkedList?', 'ArrayList is backed by an array (fast random access); LinkedList is a doubly linked list (fast insert/remove at the ends).', '2026-09-20', '2026-09-20 16:30:00');

-- sample application with a tiny valid PDF as the CV
INSERT INTO applications (student_id, job_id, cv_name, cv_file, status, applied_date)
VALUES (1, 1, 'demo_student_cv.pdf', 0x255044462d312e340a312030206f626a0a3c3c202f54797065202f436174616c6f67202f5061676573203220302052203e3e0a656e646f626a0a322030206f626a0a3c3c202f54797065202f5061676573202f4b696473205b33203020525d202f436f756e742031203e3e0a656e646f626a0a332030206f626a0a3c3c202f54797065202f50616765202f506172656e74203220302052202f4d65646961426f78205b30203020333030203134345d202f436f6e74656e7473203420302052202f5265736f7572636573203c3c202f466f6e74203c3c202f4631203520302052203e3e203e3e203e3e0a656e646f626a0a342030206f626a0a3c3c202f4c656e677468203534203e3e0a73747265616d0a4254202f4631203138205466203330203830205464202853616d706c65204356202d2044656d6f2053747564656e742920546a2045540a656e6473747265616d0a656e646f626a0a352030206f626a0a3c3c202f54797065202f466f6e74202f53756274797065202f5479706531202f42617365466f6e74202f48656c766574696361203e3e0a656e646f626a0a787265660a3020360a303030303030303030302036353533352066200a30303030303030303039203030303030206e200a30303030303030303538203030303030206e200a30303030303030313135203030303030206e200a30303030303030323431203030303030206e200a30303030303030333435203030303030206e200a747261696c65720a3c3c202f53697a652036202f526f6f74203120302052203e3e0a7374617274787265660a3431350a2525454f460a, 'Pending', '2026-09-25');
