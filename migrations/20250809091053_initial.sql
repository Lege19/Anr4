pragma foreign_keys = true; 

create table School (
    school_id INTEGER primary key
  , name text not null
) strict;

create table Student (
    student_id INTEGER primary key
  , school_id INTEGER not null references School
  , is_dyslexic integer /*boolean*/ /*maybe null*/
  , forename text not null
  , surname text not null
) strict;
create index FK_Student_School on Student(school_id);

create table Teacher (
    teacher_id INTEGER primary key
  , school_id INTEGER not null references School
  , forename text not null
  , surname text not null
) strict;
create index FK_Teacher_School on Teacher(school_id);

create table Login (
    login_id INTEGER primary key
  , email text unique not null
  , password_hash text not null -- salt is included in the text of the hash
  , student_id /*maybe null*/ integer unique references Student
  , teacher_id /*maybe null*/ integer unique references Teacher
  , check ((student_id is null) != (teacher_id is null))
) strict;
create index FK_Login_Student on Login(student_id);
create index FK_Login_Teacher on Login(teacher_id);

create table Cohort (
    cohort_id INTEGER primary key
  , school_id INTEGER not null references School
  , name text not null
  , tier_count integer not null default 1 check (tier_count != 0)
) strict;
create index FK_Cohort_School on Cohort(school_id);

create table Class (
    class_id INTEGER primary key
  , cohort_id INTEGER not null references Cohort
  , name text not null
) strict;
create index FK_Class_Cohort on Class(cohort_id);

-- Link table between Cohorts and Students
create table CohortStudent (
    cohort_id INTEGER not null references Cohort
  , student_id INTEGER not null references Student
  , class_id INTEGER not null references Class
  , tier integer not null default 0
  , primary key(cohort_id, student_id)
) strict;
create index FK_CohortStudent_Class on CohortStudent(class_id);

-- Link table between Classes and Teachers
create table ClassTeacher (
    teacher_id INTEGER not null references Teacher
  , class_id INTEGER not null references Class
  , primary key(teacher_id, class_id)
) strict;

create table Course (
    course_id INTEGER primary key
  , name text not null
  , target_language text not null
  , home_language text not null
  , tier_count integer not null default 1 check (tier_count != 0)
) strict;

-- Link table between Cohorts and Courses
create table CohortCourse (
    cohort_id INTEGER not null references Cohort
  , course_id INTEGER not null references Course
  , end_date real /*maybe null*/ -- unix timestamp
  , primary key(cohort_id, course_id)
) strict;


create table Topic (
    topic_id INTEGER primary key
  , course_id INTEGER not null references Course
  , name text not null
) strict;
create index FK_Topic_Course on Topic(course_id);

create table Word (
    word_id INTEGER primary key
  , topic_id INTEGER not null references Topic
  , headword text not null -- in target language
  , translation text not null -- in home language
  , tier integer not null
  , part_of_speech text /*maybe null*/
) strict;
create index FK_Word_Topic on Word(topic_id);

-- Link table between Students and Words
-- #parbreak()
-- ```sql null``` `last_test` indicates word has never been tested
create table StudentProgress (
    student_id INTEGER not null references Student
  , word_id INTEGER not null references Word
  , ease_factor real not null
  , test_interval real not null -- in seconds
  , last_test real /*maybe null*/ -- unix timestamp
  , primary key(student_id, word_id)
) strict;

create table Session (
    session_id INTEGER primary key
  , student_id INTEGER not null references Student
  , start real not null -- unix timestamp
  , length real not null -- measured in seconds
) strict;
create index FK_Session_Student on Session(student_id);

create table SessionTopic (
    session_id INTEGER not null references Session
  , topic_id INTEGER not null references Topic
  , questions_answered integer not null
  , progress real not null
  , primary key(session_id, topic_id)
) strict;

create table RefreshToken (
    token blob primary key
  , login_id INTEGER not null references Login
  , expiration real not null -- unix timestamp
) strict;
create index FK_RefreshToken_Login on RefreshToken(login_id);
