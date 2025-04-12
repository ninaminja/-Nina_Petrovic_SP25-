BEGIN;

--creating schema
CREATE SCHEMA IF NOT EXISTS recruitment;

-- Create tables in dependency order (referenced tables first)

-- 1. Health condition (referenced by candidate and job_health)
CREATE TABLE IF NOT EXISTS health_condition (
    health_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    CONSTRAINT unique_health_condition_name UNIQUE (name)
);

-- 2. Job category (referenced by job)
CREATE TABLE IF NOT EXISTS job_category (
    cat_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    CONSTRAINT unique_job_category_name UNIQUE (name)
);

-- 3. Skill (referenced by candidate_skill and service_request)
CREATE TABLE IF NOT EXISTS skill (
    skill_id SERIAL PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL,
    skill_category VARCHAR(50),
    CONSTRAINT unique_skill_name UNIQUE (skill_name)
);

-- 4. Recruiter (referenced by interview and service_request)
CREATE TABLE IF NOT EXISTS recruiter (
    rec_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    department VARCHAR(50) NOT NULL,
    CONSTRAINT unique_recruiter_email UNIQUE (email),
    CONSTRAINT unique_recruiter_phone UNIQUE (phone)
);

-- 5. Candidate (references health_condition)
CREATE TABLE IF NOT EXISTS candidate (
    candidate_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    full_name VARCHAR(100) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    resume TEXT,
    experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0),
    education VARCHAR(50) NOT NULL CHECK (education IN (
        'High School', 'Associate', 'Bachelor', 'Master', 'PhD', 'Other'
    )),
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN (
        'Active', 'Inactive', 'Placed', 'Archived'
    )),
    health_id INTEGER NOT NULL,
    CONSTRAINT unique_candidate_email UNIQUE (email),
    CONSTRAINT unique_candidate_phone UNIQUE (phone)
);

-- 6. Job (references job_category)
CREATE TABLE IF NOT EXISTS job (
    job_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    requirements TEXT,
    salary DECIMAL(10,2) NOT NULL CHECK (salary > 0),
    location VARCHAR(100),
    posted_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (status IN (
        'Open', 'Closed'
    )),
    job_type VARCHAR(50) NOT NULL CHECK (job_type IN (
        'Full-time', 'Part-time', 'Contract', 'Temporary', 'Internship'
    )),
    cat_id INTEGER NOT NULL,
    CONSTRAINT unique_job_title UNIQUE (title)
);

-- 7. Placement (references candidate and job)
CREATE TABLE IF NOT EXISTS placement (
    placement_id SERIAL PRIMARY KEY,
    start_date DATE NOT NULL,
    salary DECIMAL(10,2) NOT NULL CHECK (salary > 0),
    candidate_id INTEGER NOT NULL,
    job_id INTEGER NOT NULL,
    CONSTRAINT unique_placement UNIQUE (candidate_id)
);

-- 8. Candidate_skill (references candidate and skill)
CREATE TABLE IF NOT EXISTS candidate_skill (
    cand_sk_id SERIAL PRIMARY KEY,
    skill_id INTEGER NOT NULL,
    candidate_id INTEGER NOT NULL,
    CONSTRAINT unique_candidate_skill UNIQUE (skill_id, candidate_id)
);

-- 9. Application (references candidate and job)
CREATE TABLE IF NOT EXISTS application (
    appl_id SERIAL PRIMARY KEY,
    applied_date DATE NOT NULL DEFAULT CURRENT_DATE,
    candidate_id INTEGER NOT NULL,
    job_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Submitted' CHECK (status IN (
        'Pending', 'Interview', 'Declined'
    )),
    CONSTRAINT unique_application UNIQUE (candidate_id, job_id)
);

-- 10. Interview (references candidate, job and recruiter)
CREATE TABLE IF NOT EXISTS interview (
    inter_id SERIAL PRIMARY KEY,
    interview_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Scheduled' CHECK (status IN (
         'Completed', 'Cancelled', 'Waiting'
    )),
    feedback TEXT,
    candidate_id INTEGER NOT NULL,
    job_id INTEGER NOT NULL,
    rec_id INTEGER NOT NULL
);

-- 11. Job_health (references job and health_condition)
CREATE TABLE IF NOT EXISTS job_health (
    job_health_id SERIAL PRIMARY KEY, 
    job_id INTEGER NOT NULL,
    health_id INTEGER NOT NULL,
    CONSTRAINT unique_job_health UNIQUE (job_id, health_id)
);

-- 12. Service_request (references candidate, recruiter and skill)
CREATE TABLE IF NOT EXISTS service_request (
    service_id SERIAL PRIMARY KEY,
    date_of_service DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'Requested' CHECK (status IN (
        'Pending', 'Complete'
    )),
    candidate_id INTEGER NOT NULL,
    rec_id INTEGER NOT NULL,
    service_type VARCHAR(50) NOT NULL CHECK (service_type IN (
        'Interview coaching', 'Skills development','Resume writing' 
    )),
    skill_id INTEGER,
    description TEXT,
    record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

-- I added FK to every table separated of creating table
ALTER TABLE candidate 
ADD CONSTRAINT fk_candidate_health
FOREIGN KEY (health_id) REFERENCES health_condition(health_id);

ALTER TABLE job 
ADD CONSTRAINT fk_job_category
FOREIGN KEY (cat_id) REFERENCES job_category(cat_id);

ALTER TABLE placement 
ADD CONSTRAINT fk_placement_candidate
FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_placement_job
FOREIGN KEY (job_id) REFERENCES job(job_id),
ADD CONSTRAINT date_placement_2000
CHECK (start_date > DATE '2000-01-01');

ALTER TABLE candidate_skill 
ADD CONSTRAINT fk_candidate_skill_skill
FOREIGN KEY (skill_id) REFERENCES skill(skill_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_candidate_skill_candidate
FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id) ON DELETE CASCADE;

ALTER TABLE application 
ADD CONSTRAINT fk_application_candidate
FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_application_job
FOREIGN KEY (job_id) REFERENCES job(job_id) ON DELETE CASCADE,
ADD CONSTRAINT date_appl_2000
CHECK (applied_date > DATE '2000-01-01');

ALTER TABLE interview 
ADD CONSTRAINT fk_interview_candidate
FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_interview_job
FOREIGN KEY (job_id) REFERENCES job(job_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_interview_recruiter
FOREIGN KEY (rec_id) REFERENCES recruiter(rec_id),
ADD CONSTRAINT future_interview_date 
CHECK (interview_date > CURRENT_DATE - INTERVAL  '1 day');

ALTER TABLE job_health 
ADD CONSTRAINT fk_job_health_job
FOREIGN KEY (job_id) REFERENCES job(job_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_job_health_condition
FOREIGN KEY (health_id) REFERENCES health_condition(health_id) ON DELETE CASCADE;

ALTER TABLE service_request 
ADD CONSTRAINT fk_service_request_candidate
FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_service_request_recruiter
FOREIGN KEY (rec_id) REFERENCES recruiter(rec_id) ON DELETE CASCADE,
ADD CONSTRAINT fk_service_request_skill
FOREIGN KEY (skill_id) REFERENCES skill(skill_id) ON DELETE CASCADE,
ADD CONSTRAINT date_service_2000
CHECK (date_of_service > DATE '2000-01-01');

ALTER TABLE job 
ADD CONSTRAINT date_job_2000
CHECK (posted_date > DATE '2000-01-01');



--adding record_ts to all tables 

ALTER TABLE candidate 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE placement 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE job_category 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE recruiter 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE skill
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE candidate_skill 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE job
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE application 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE interview 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE health_condition 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE job_health 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE service_request 
ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;



-- Insert data with proper conflict handling


-- Health conditions, here i fixed part where i hardcoded IDs, and I added ON CONFLICT () DO NOTHING
INSERT INTO health_condition (name, description)
VALUES 
    ('Without condition', 'No special treatment needed'),
    ('Anxiety disorder', 'Flexible work environment needed')
ON CONFLICT (name) DO NOTHING;

-- Job categories
INSERT INTO job_category (name, description)
VALUES 
    ('IT & Software', 'Tech jobs'),
    ('Mechanical engeneering', 'Engeneering jobs')
ON CONFLICT (name) DO NOTHING;

-- Skills
INSERT INTO skill (skill_name)
VALUES 
    ('Python'),
    ('SQL')
ON CONFLICT (skill_name) DO NOTHING;

-- Recruiters
INSERT INTO recruiter (first_name, last_name, email, phone, department)
VALUES 
    ('Mark', 'Johnson', 'mark.hr@email.com', '555123', 'HR'),
    ('Maria', 'Smith', 'maria.hr@email.com', '77773529', 'HR')
ON CONFLICT (email) DO NOTHING;

-- Candidates, here i fixed my JOINs, i wanted to connecnt health condition name with candidate so I used more simple way that's working
INSERT INTO candidate (first_name, last_name, email, phone, resume, experience, education, status, health_id)
SELECT 
    'John', 'Doe', 'john.doe@email.com', '123456789', 'resume.pdf', 5, 'Bachelor', 'Placed', hc.health_id
FROM health_condition hc WHERE hc.name = 'Without condition'
ON CONFLICT (email) DO NOTHING;

INSERT INTO candidate (first_name, last_name, email, phone, resume, experience, education, status, health_id)
SELECT 
    'Jane', 'Smith', 'jane.smith@email.com', '987654321', 'mycv.pdf', 2, 'Master', 'Active', hc.health_id
FROM health_condition hc WHERE hc.name = 'Anxiety disorder'
ON CONFLICT (email) DO NOTHING;

-- Jobs, here i connected job category with job where category is showed with specific job
INSERT INTO job (title, description, requirements, salary, location, posted_date, status, job_type, cat_id)
SELECT 
    'Software Engineer', 'Backend Developer', 'Python, SQL, PHP', 5000.00, 'Remote', '2025-03-10', 'Open', 'Full-time', jc.cat_id
FROM job_category jc WHERE jc.name = 'IT & Software'
ON CONFLICT (title) DO NOTHING;

INSERT INTO job (title, description, requirements, salary, location, posted_date, status, job_type, cat_id)
SELECT 
    'Data Analyst', 'Data visualization role', 'Excel, PowerBI', 4000.00, 'On-site', '2023-07-11', 'Closed', 'Contract', jc.cat_id
FROM job_category jc WHERE jc.name = 'IT & Software'
ON CONFLICT (title) DO NOTHING;

-- Applications, here i used JOIN to connect job with application, so based on specific title of job we can join ID of job with applicaton
--I connected candidate through email, so this part will show what ID of customer is in application
INSERT INTO application (applied_date, candidate_id, job_id, status)
SELECT 
    '2025-03-12', c.candidate_id, j.job_id, 'Pending'
FROM candidate c
JOIN job j ON j.title = 'Software Engineer'
WHERE c.email = 'john.doe@email.com'
ON CONFLICT (candidate_id, job_id) DO NOTHING;

INSERT INTO application (applied_date, candidate_id, job_id, status)
SELECT 
    '2023-08-01', c.candidate_id, j.job_id, 'Interview'
FROM candidate c
JOIN job j ON j.title = 'Data Analyst'
WHERE c.email = 'jane.smith@email.com'
ON CONFLICT (candidate_id, job_id) DO NOTHING;

-- Placements, same, i used job title to show what job is in qestion to connect with placement 
-- same with placement, I use email of candidate to show what candidate is in question and to connect it with placement 
INSERT INTO placement (start_date, salary, candidate_id, job_id)
SELECT
    '2025-05-10', 2000.00, c.candidate_id, j.job_id
FROM candidate c
JOIN job j ON j.title = 'Software Engineer'
WHERE c.email = 'john.doe@email.com'
ON CONFLICT (candidate_id) DO NOTHING;

INSERT INTO placement (start_date, salary, candidate_id, job_id)
SELECT
    '2023-08-20', 1500.00, c.candidate_id, j.job_id
FROM candidate c
JOIN job j ON j.title = 'Data Analyst'
WHERE c.email = 'jane.smith@email.com'
ON CONFLICT (candidate_id) DO NOTHING;

-- Interviews, I will join job and recruiter as well for true information of interview
-- i'll connect email too to show what candidate is in question
INSERT INTO interview (interview_date, status, feedback, candidate_id, job_id, rec_id)
SELECT 
    '2025-05-08', 'Completed', 'Strong skills', c.candidate_id, j.job_id, r.rec_id
FROM candidate c
JOIN job j ON j.title = 'Software Engineer'
JOIN recruiter r ON r.first_name = 'Maria'
WHERE c.email = 'john.doe@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO interview (interview_date, status, feedback, candidate_id, job_id, rec_id)
SELECT 
    '2025-08-12', 'Completed', 'Strong skills, specifically soft skills', c.candidate_id, j.job_id, r.rec_id
FROM candidate c
JOIN job j ON j.title = 'Data Analyst'
JOIN recruiter r ON r.first_name = 'Mark'
WHERE c.email = 'jane.smith@email.com'
ON CONFLICT DO NOTHING;

-- Candidate skills, join is for connecting skill with right candidate 
--email is too, to show what cadidate is in question
INSERT INTO candidate_skill (skill_id, candidate_id)
SELECT 
    s.skill_id, c.candidate_id
FROM candidate c
JOIN skill s ON s.skill_name = 'Python'
WHERE c.email = 'john.doe@email.com'
ON CONFLICT (skill_id, candidate_id) DO NOTHING;

INSERT INTO candidate_skill (skill_id, candidate_id)
SELECT 
    s.skill_id, c.candidate_id
FROM candidate c
JOIN skill s ON s.skill_name = 'SQL'
WHERE c.email = 'jane.smith@email.com'
ON CONFLICT (skill_id, candidate_id) DO NOTHING;

-- Service requests, we need join to show what recruiter will do service and email of candidate as well to show what candidate is asked for service (in table we will have ID of candidate)
INSERT INTO service_request (date_of_service, status, candidate_id, rec_id, service_type, skill_id)
SELECT 
    '2025-03-10', 'Complete', c.candidate_id, r.rec_id, 'Interview coaching', NULL
FROM candidate c
JOIN recruiter r ON r.first_name = 'Maria'
WHERE c.email = 'john.doe@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO service_request (date_of_service, status, candidate_id, rec_id, service_type, skill_id)
SELECT 
    '2023-08-05', 'Complete', c.candidate_id, r.rec_id, 'Interview coaching', NULL
FROM candidate c
JOIN recruiter r ON r.first_name = 'Mark'
WHERE c.email = 'jane.smith@email.com'
ON CONFLICT DO NOTHING;

-- Job health conditions, here I used join to connect condition with job which is associated with canddiate too but in this table is with informatios of job and health condition
INSERT INTO job_health (job_id, health_id)
SELECT 
    j.job_id, hc.health_id
FROM job j
JOIN health_condition hc ON hc.name = 'Without condition'
WHERE j.title = 'Software Engineer'
ON CONFLICT (job_id, health_id) DO NOTHING;

INSERT INTO job_health (job_id, health_id)
SELECT 
    j.job_id, hc.health_id
FROM job j
JOIN health_condition hc ON hc.name = 'Anxiety disorder'
WHERE j.title = 'Data Analyst'
ON CONFLICT (job_id, health_id) DO NOTHING;

COMMIT;