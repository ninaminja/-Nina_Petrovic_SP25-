--first i created candidate table with all needed columns
CREATE TABLE IF NOT EXISTS candidate (
    candidate_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    resume TEXT,
    experience INTEGER NOT NULL DEFAULT 0 CHECK (experience >= 0), -- Cannot be negative
    education VARCHAR(50) NOT NULL CHECK (education IN (
        'High School', 'Associate', 'Bachelor', 'Master', 'PhD', 'Other'
    )), -- Restricted values
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN (
        'Active', 'Inactive', 'Placed', 'Archived'
    )),
    CONSTRAINT unique_candidate_email UNIQUE (email), -- Email must be unique
    CONSTRAINT unique_candidate_phone UNIQUE (phone) -- Phone must be unique
);
--i made a mistake while naming so i renamed this column to match logical diagram
ALTER TABLE public.candidate RENAME COLUMN education_level TO education;

--this part will create FK health_id to candidate table
ALTER TABLE candidate 
ADD COLUMN health_id integer;

UPDATE candidate c 
SET health_id = (SELECT health_id FROM health_condition hc LIMIT 1)
WHERE health_id IS NULL;

ALTER TABLE candidate 
ALTER COLUMN health_id SET NOT NULL;

ALTER TABLE candidate 
ADD CONSTRAINT fk_candidate_health
FOREIGN KEY (health_id) REFERENCES health_condition(health_id);

-- this is creating palcement table

CREATE TABLE IF NOT EXISTS placement (
    placement_id SERIAL PRIMARY KEY,
    start_date DATE NOT NULL, -- Date constraint
    salary DECIMAL(10,2) NOT NULL CHECK (salary > 0), -- Must be positive
    candidate_id INTEGER NOT NULL REFERENCES candidate(candidate_id) ON DELETE CASCADE,
    CONSTRAINT unique_placement UNIQUE (candidate_id) -- Prevent duplicate placements
);

--there I added check for date in placement table so we can't enter date before 01-01-2000

ALTER TABLE placement 
ADD CONSTRAINT date_after_2000
CHECK (start_date > DATE '2000-01-01');

--this is also part of making a FK job_id to placement table

ALTER TABLE placement
ADD COLUMN job_id integer;

UPDATE placement p 
SET job_id = (SELECT job_id FROM job LIMIT 1)
WHERE job_id IS NULL;


ALTER TABLE placement 
ALTER COLUMN job_id SET NOT NULL;

ALTER TABLE placement 
ADD CONSTRAINT fk_placement_job
FOREIGN KEY (job_id) REFERENCES job(job_id);


--this is table job_category

CREATE TABLE job_category (
    cat_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255)
);

-- this is creating recruiter table

CREATE TABLE IF NOT EXISTS recruiter (
    rec_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    department VARCHAR(50) NOT NULL,
    CONSTRAINT unique_recruiter_email UNIQUE (email), -- Email must be unique
    CONSTRAINT unique_recruiter_phone UNIQUE (phone) -- Phone must be unique
);

--this is creating skill table 

CREATE TABLE IF NOT EXISTS skill (
    skill_id SERIAL PRIMARY KEY,
    skill_name VARCHAR(100) NOT NULL,
    skill_category VARCHAR(50)
);

--there i will make candidate_skill table but i added FK while making table - candidate_id

CREATE TABLE IF NOT EXISTS candidate_skill (
    cand_sk_id serial PRIMARY KEY,
    skill_id INTEGER NOT NULL REFERENCES skill(skill_id) ON DELETE CASCADE,
    candidate_id INTEGER NOT NULL REFERENCES candidate(candidate_id) ON DELETE CASCADE,
    CONSTRAINT unique_candidate_skill UNIQUE (skill_id, candidate_id) -- No duplicate skill entries
);

--tehre we will make job table 

CREATE TABLE IF NOT EXISTS job (
    job_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    requirements TEXT,
    salary DECIMAL(10,2) NOT NULL CHECK (salary > 0), -- Must be positive
    location VARCHAR(100),
    posted_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (status IN (
        'Open', 'Closed'
    )), -- Restricted values with default
    job_type VARCHAR(50) NOT NULL CHECK (job_type IN (
        'Full-time', 'Part-time', 'Contract', 'Temporary', 'Internship'
    )), -- Restricted values
    cat_id INTEGER NOT NULL REFERENCES job_category(cat_id) ON DELETE CASCADE,
);

--I added check for date again, date cant be entered after 01-01-2000
ALTER TABLE job 
ADD CONSTRAINT date_after_2000
CHECK (posted_date > DATE '2000-01-01');

--creating table application, here i have deafult for status column which is 'Submitted' and we can enter just 'Pending', 'Interview' or 'Declined'
--if we don't specify applied_date it will automatically set current date 
--i added FK job_id and candidate_id too

CREATE TABLE IF NOT EXISTS application (
    appl_id SERIAL PRIMARY KEY,
    applied_date DATE NOT NULL DEFAULT CURRENT_DATE,
    candidate_id INTEGER NOT NULL REFERENCES candidate(candidate_id) ON DELETE CASCADE,
    job_id INTEGER NOT NULL REFERENCES job(job_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'Submitted' CHECK (status IN (
        'Pending', 'Interview', 'Declined'
    )), -- Restricted values with default
);
--this is check for applied_date
ALTER TABLE application 
ADD CONSTRAINT date_after_2000
CHECK (applied_date  > DATE '2000-01-01');

--this is creating interview table 
--for status we have deafult Scheduled and we can enter just 'Completed', 'Cancelled'or 'Waiting'
--i thought that TIMESTAMP would be good for date but i realized it's not so i changed it do DATE
CREATE TABLE IF NOT EXISTS interview (
    inter_id SERIAL PRIMARY KEY,
    interview_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Scheduled' CHECK (status IN (
         'Completed', 'Cancelled', 'Waiting'
    )), -- Restricted values with default
    feedback TEXT,
    candidate_id INTEGER NOT NULL REFERENCES candidate(candidate_id) ON DELETE CASCADE,
    job_id INTEGER NOT NULL REFERENCES job(job_id) ON DELETE CASCADE,
    rec_id INTEGER NOT NULL REFERENCES recruiter(rec_id),
    CONSTRAINT future_interview_date CHECK (interview_date > CURRENT_TIMESTAMP - INTERVAL '1 day') -- Typically in future
);
--query for changing TIMESPAM to DATE
ALTER TABLE interview 
ALTER COLUMN interview_date TYPE DATE
USING interview_date::DATE;

--this is creation of health_condition table
CREATE TABLE IF NOT EXISTS health_condition(
		health_id SERIAL PRIMARY KEY,
		name VARCHAR(100),
		description TEXT,
		record_ts DATE NOT NULL DEFAULT CURRENT_DATE
);

-- creating job_health 
--i added FKs job_id and healt_id in this query

CREATE TABLE IF NOT EXISTS job_health(
		job_health_id SERIAL PRIMARY KEY, 
		job_id INTEGER NOT NULL REFERENCES job(job_id) ON DELETE CASCADE,
		health_id INTEGER NOT NULL REFERENCES health_condition(health_id) ON DELETE CASCADE
);

--here i have creation of service_request 
--i have date of service, if we don't enter date it will be current 
-- i have two CHECKs : for status and service type
-- for status we have deafult Requested and we can choose  'Pending' or 'Complete'
-- for service type we can choose  'Interview coaching', 'Skills development' or 'Resume writing'
--i changed name of date because it's reserved word, so here is date_of_service
CREATE TABLE IF NOT EXISTS service_request (
    service_id SERIAL PRIMARY KEY,
    date_of_service DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'Requested' CHECK (status IN (
        'Pending', 'Complete'
    )), -- Restricted values with default
    candidate_id INTEGER NOT NULL REFERENCES candidate(candidate_id) ON DELETE CASCADE,
    rec_id INTEGER NOT NULL REFERENCES recruiter(rec_id) ON DELETE CASCADE,
    service_type VARCHAR(50) NOT NULL CHECK (service_type IN (
        'Interview coaching', 'Skills development','Resume writing' 
    )), -- Restricted values
    skill_id INTEGER REFERENCES skill(skill_id) ON DELETE CASCADE,
    description TEXT
);
--this is also check for date which cant be before 01-01-2000
ALTER TABLE service_request 
ADD CONSTRAINT date_after_2000
CHECK (date_of_service  > DATE '2000-01-01');



-- I wanted to find some code which I can add this column to every table but i couldn't find any solution so I used classic ALERT for every table 
 
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


--inserting data into columns 


--health_condition table

INSERT INTO health_condition (health_id, name, description)
SELECT
		1,
		'Without condition',
		'No special treatment needed'
		
INSERT INTO health_condition (health_id, name, description)
SELECT
		2,
		'Anxiety disorder',
		'Flexible work environment needed'

		
--cadidate table
		
INSERT INTO candidate (candidate_id, first_name, last_name, email, phone, resume, experience, education, status, health_id)
SELECT 
	1,	
	'John',
	'Doe',
	'john.doe@email.com',
	'123456789',
	'resume.pdf',
	5,
	'Bachelor',
	'Placed',
	1
	
INSERT INTO candidate (candidate_id, first_name, last_name, email, phone, resume, experience, education, status, health_id)
SELECT 
	2,	
	'Jane',
	'Smith',
	'jane.smith@email.com',
	'987654321',
	'mycv.pdf',
	2,
	'Master',
	'Active',
	2
	
--job_category table

INSERT INTO job_category (cat_id, name, description)
SELECT 
		1,
		'IT & Software',
		'Tech jobs'

INSERT INTO job_category (cat_id, name, description)
SELECT 
		2,
		'Mechanical engeneering',
		'Engeneering jobs'
		
--job 
INSERT INTO job(job_id, title, description, requirements, salary, "location", posted_date, status, job_type,cat_id)
SELECT 
		1,
		'Software Engineer',
		'Backend Developer',
		'Python, SQL, PHP',
		5000.00,
		'Remote',
		'2025-03-10',
		'Open',
		'Full-time',
		1
		
INSERT INTO job(job_id, title, description, requirements, salary, "location", posted_date, status, job_type,cat_id)
SELECT 
		2,
		'Data Analyst',
		'Data visualization role',
		'Excel, PowerBI',
		4000.00,
		'On-site',
		'2023-07-11',
		'Closed',
		'Contract',
		1
		
--application table
--i connected job based on title and candidate based on ID so i tried to avoid harcoding
		
INSERT INTO application (appl_id, applied_date, candidate_id, job_id, status)
SELECT 
    1,  
    '2025-03-12',  
    c.candidate_id,  
    j.job_id,  
    'Pending' 
FROM candidate c
JOIN job j ON j.title = 'Software Developer' 
WHERE c.candidate_id = 1;

INSERT INTO application (appl_id, applied_date, candidate_id, job_id, status)
SELECT 
    2,  
    '2023-08-01', 
    c.candidate_id,  
    j.job_id,  
    'Interview'  
FROM candidate c
JOIN job j ON j.title = 'Data Analyst'  
WHERE c.candidate_id = 2;
		
--inserting to placement table
--here i connected job and candidate based on title and candidate ID 
		
INSERT INTO placement (placement_id, start_date, salary, candidate_id, job_id)
SELECT
    1,  
    '2025-05-10', 
    2000.00,  
    c.candidate_id,  
    j.job_id  
FROM candidate c
JOIN job j ON j.title = 'Software Developer' 
WHERE c.candidate_id = 1;

INSERT INTO placement (placement_id, start_date, salary, candidate_id, job_id)
SELECT
    2,  
    '2023-08-20',  
    1500.00,  
    c.candidate_id,  
    j.job_id  
FROM candidate c
JOIN job j ON j.title = 'Data Analyst'  
WHERE c.candidate_id = 2;
		
--recruiter table

		INSERT INTO recruiter (rec_id, first_name, last_name, email, phone, department)
SELECT 
		1,
		'Mark',
		'Johnson',
		'mark.hr@email.com',
		'555123',
		'HR'
		
		INSERT INTO recruiter (rec_id, first_name, last_name, email, phone, department)
SELECT 
		2,
		'Maria',
		'Smith',
		'maria.hr@email.com',
		'77773529',
		'HR'
		
		
--interview table
		
--i connected candidate and job to avoid hardcoding 
--i connected recuiter based on his/her neme, job based on title and candidate based on ID
		
INSERT INTO interview (inter_id, interview_date, status, feedback, candidate_id, job_id, rec_id)
SELECT 
    1,  
    '2025-05-08',  
    'Completed',  
    'Strong skills',  
    c.candidate_id,  
    j.job_id,  
    r.rec_id  
FROM candidate c
JOIN job j ON j.title = 'Software Developer'  
JOIN recruiter r ON r.first_name  = 'Maria' 
WHERE c.candidate_id = 1;

INSERT INTO interview (inter_id, interview_date, status, feedback, candidate_id, job_id, rec_id)
SELECT 
    2,  -- inter_id
    '2025-08-12',  
    'Completed',  
    'Strong skills, specifically soft skills',  
    c.candidate_id,  
    j.job_id,  
    r.rec_id  
FROM candidate c
JOIN job j ON j.title = 'Data Analyst' 
JOIN recruiter r ON r.first_name  = 'Mark' 
WHERE c.candidate_id = 2;
		
		
		
--skill table 
		
		INSERT INTO skill (skill_id, skill_name)
SELECT
		1,
		'python'
		
		INSERT INTO skill (skill_id, skill_name)
SELECT
		2,
		'SQL'
		

--this is for candidate_skill table, i tried to use this query to avoid hardcoding
-- i used join to connect skill and candidate, skill for name and candidate for ID
-- i used where to specify which candidate is in question
		
		INSERT INTO candidate_skill (cand_sk_id, skill_id, candidate_id)
SELECT 
    cs.cand_sk_id,   
    s.skill_id,      
    c.candidate_id   
FROM candidate c
JOIN skill s ON s.skill_name = 'python' 
JOIN candidate_skill cs ON cs.candidate_id = c.candidate_id
WHERE c.candidate_id = 1;

INSERT INTO candidate_skill (cand_sk_id, skill_id, candidate_id)
SELECT 
    cs.cand_sk_id,   
    s.skill_id,      
    c.candidate_id   
FROM candidate c
JOIN skill s ON s.skill_name = 'SQL' 
JOIN candidate_skill cs ON cs.candidate_id = c.candidate_id
WHERE c.candidate_id = 2;

--service_request table, i tried to use join to avoid harcoding for candidate and rec_id
-- based on name of recruiter and cadidate ID we will connect those two

INSERT INTO service_request (service_id, date_of_service, status, candidate_id, rec_id, service_type, skill_id)
SELECT 
    1,
    '2025-03-10',
    'Complete', 
    c.candidate_id,
    r.rec_id,
    'Interview coaching',
    null
FROM candidate c
JOIN recruiter r ON r.first_name  = 'Maria'  
WHERE c.candidate_id = 1;

INSERT INTO service_request (service_id, date_of_service, status, candidate_id, rec_id, service_type, skill_id)
SELECT 
    2,
    '2023-08-05',
    'Complete', 
    c.candidate_id,
    r.rec_id,
    'Interview coaching',
    null
FROM candidate c
JOIN recruiter r ON r.first_name  = 'Mark'  
WHERE c.candidate_id = 2;

--job_health table, i used here similar query like candidate_skill so i can avoid hardcoding
--i used join to connect informations, name from health_condition (which condition is actually) and job to connect to job_health, to specify what job is in question
--and where is to write what job exactly is 

		INSERT INTO job_health (job_health_id, job_id, health_id)
SELECT 
    jh.job_health_id,   
    j.job_id,           
    hc.health_id        
FROM job j
JOIN health_condition hc  ON hc.name = 'Without condition'
JOIN job_health jh ON jh.job_id = j.job_id
WHERE j.job_id = 1;

INSERT INTO job_health (job_health_id, job_id, health_id)
SELECT 
    jh.job_health_id,   
    j.job_id,          
    hc.health_id         
FROM job j
JOIN health_condition hc  ON hc.name = 'Anxiety disorder'
JOIN job_health jh ON jh.job_id = j.job_id
WHERE j.job_id = 2;
		