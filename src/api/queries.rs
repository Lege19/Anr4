//! Defines a collection of api routes which are relatively simple queries to the database
use std::collections::HashMap;

use axum::{Json, extract::State, http::StatusCode, response::IntoResponse};
use serde::{Deserialize, Serialize};
use sqlx::{Pool, Sqlite};
use tracing::{error, warn};

use crate::{
    auth::{StudentId, TeacherId},
    database::{DatabaseState, RowId},
    server_state::ServerState,
};

/// Blanket error handler used in this module for when a query fails in some way
fn error_handler(error: sqlx::Error) -> StatusCode {
    match error {
        sqlx::Error::Database(e) => {
            error!(%e);
            StatusCode::INTERNAL_SERVER_ERROR
        }
        sqlx::Error::PoolClosed => {
            warn!("SQLite connection pool closed unexpectedly");
            StatusCode::SERVICE_UNAVAILABLE
        }
        sqlx::Error::RowNotFound => StatusCode::BAD_REQUEST,
        sqlx::Error::PoolTimedOut => {
            warn!("SQLite connection pool timed out");
            StatusCode::SERVICE_UNAVAILABLE
        }
        e => {
            error!(%e, "Unknown error");
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}

/// Helper type needed for getting optional boolean values from the database
///
/// Doesn't do much, can probably be ignored.
#[derive(Serialize)]
struct OptionalBool(Option<bool>);
impl From<Option<i64>> for OptionalBool {
    fn from(value: Option<i64>) -> Self {
        Self(value.map(|i64| i64 != 0))
    }
}

/// Used in the response type for [student_info]
///
/// Fields correspond to the columns of the `Student` table in the database
#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct Student {
    /// The ID of the student authenticated as,
    /// this will match the claims of the access token used for the request
    student_id: RowId,
    /// The id of the school this student is associated with
    school_id: RowId,
    /// Whether this student is dyslexic
    /// This is optional because this may be unknown
    is_dyslexic: OptionalBool,
    /// First name of the student
    forename: String,
    /// Last name of the student
    surname: String,
}
/// Represents and entry in the link table `CohortStudent`
///
/// The reason this is a separate type (unlike in the case part_of_speech `CohortCourse`)
#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct StudentCohort {
    /// The tier at which this student studies courses in this cohort.
    ///
    /// E.g. 0 corresponds to Foundation tier and 1 corresponds to higher tier for GCSE courses
    tier: i64,
    /// The ID of the class in this cohort the student is in
    class_id: RowId,
}
/// Bundles a [Student] with a [HashMap] from (cohort IDs)[RowId] to [StudentCohort]s
#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct StudentWithCohorts {
    #[serde(flatten)]
    /// Core student information, directly corresponding to a row in `Student` in the database
    student: Student,
    /// A [HashMap] with an entry for each cohort the student is in
    ///
    /// The keys are the IDs of the cohorts,
    /// and the values correspond to the non-foreign key colmuns of `CohortStudent`
    cohorts: HashMap<RowId, StudentCohort>,
}
/// Handler for `/api/student_info`
///
/// Returns basic information about the student authenticated as.
pub async fn student_info(
    StudentId(student_id): StudentId,
    State(ServerState {
        database: DatabaseState(ref database),
        ..
    }): State<ServerState>,
) -> impl IntoResponse {
    tokio::try_join!(
        async {
            sqlx::query_as!(
                Student,
                r#"
                select
                    student_id
                  , school_id
                  , is_dyslexic
                  , forename
                  , surname
                from Student where student_id = ?"#,
                student_id,
            )
            .fetch_one(database)
            .await
            .map_err(error_handler)
        },
        async {
            sqlx::query!(
                r#"select cohort_id as "cohort_id: RowId", tier, class_id as "class_id: RowId" from CohortStudent where student_id = ?"#,
                student_id
            )
            .fetch_all(database)
            .await
            .map_err(error_handler)
        }
    ).map(|(student, cohorts)| StudentWithCohorts {
        student,
        cohorts: HashMap::from_iter(cohorts.into_iter().map(|cohort| {
            (
                cohort.cohort_id,
                StudentCohort {
                    tier: cohort.tier,
                    class_id: cohort.class_id,
                },
            )
        })),
    })
    .map(Json)
}

/// The response type for [teacher_info]
///
/// Fields correspond to the columns of the `Teacher` table in the database.
#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct Teacher {
    /// The teacher's ID
    teacher_id: RowId,
    /// The ID of the school the teacher works at
    school_id: RowId,
    /// The forename of the teacher
    forename: String,
    /// The surname of the teacher
    surname: String,
}

/// Handler for `/api/teacher_info`
///
/// Returns basic information about the teacher authenticated as.
///
/// Response body is a [Teacher] serialized in JSON.
pub async fn teacher_info(
    TeacherId(teacher_id): TeacherId,
    State(ServerState {
        database: DatabaseState(ref database),
        ..
    }): State<ServerState>,
) -> impl IntoResponse {
    sqlx::query_as!(
        Teacher,
        r#"
                select
                    teacher_id
                  , school_id
                  , forename
                  , surname
                from Teacher where teacher_id = ?"#,
        teacher_id,
    )
    .fetch_one(database)
    .await
    .map_err(error_handler)
    .map(Json)
}

/// Module to bundle items relating to queries relating to cohorts
mod cohort {
    use super::*;
    /// Core cohort information, directly corresponding to a row in `Cohort` in the database
    #[derive(Serialize)]
    #[serde(rename_all = "camelCase")]
    struct Cohort {
        /// The ID of this cohort
        cohort_id: RowId,
        /// The ID of the school this cohort belongs to
        school_id: RowId,
        /// The name of this cohort
        name: String,
        /// The number of tiers this cohort is divided into
        tier_count: i64,
    }

    /// A list of these are returned in JSON as the body of [cohorts]
    #[derive(Serialize)]
    #[serde(rename_all = "camelCase")]
    struct CohortWithCourses {
        #[serde(flatten)]
        /// Core cohort information, directly corresponding to a row in `Cohort` in the database
        cohort: Cohort,
        /// A list of courses studied by this cohort, corresponding to rows in `CohortCourse`
        courses: Vec<RowId>,
    }
    /// Get basic information about a single cohort,
    ///
    /// Includes checks that the student is a member of the cohort
    async fn cohort(
        student_id: RowId,
        database: Pool<Sqlite>,
        cohort_id: RowId,
    ) -> Result<CohortWithCourses, sqlx::Error> {
        sqlx::query_scalar!(
            r#"
            select 0 from CohortStudent
            where
                student_id = ?1
            and cohort_id = ?2
            "#,
            student_id,
            cohort_id,
        )
        .fetch_one(&database)
        .await?;
        tokio::try_join!(
            async {
                sqlx::query_as!(
                    Cohort,
                    r#"
                    select
                        cohort_id
                      , school_id
                      , name
                      , tier_count
                    from Cohort
                    where cohort_id = ?
                    "#,
                    cohort_id
                )
                .fetch_one(&database)
                .await
            },
            async {
                sqlx::query_scalar!(
                    r#"
                    select course_id as 'course_id: RowId'
                    from CohortCourse
                    where cohort_id = ?
                    "#,
                    cohort_id,
                )
                .fetch_all(&database)
                .await
            }
        )
        .map(|(cohort, courses)| CohortWithCourses { cohort, courses })
    }
    /// Handler for `/api/data/cohorts`
    ///
    /// Returns basic information about each of the requested cohorts,
    /// which must be a subset of the cohorts of the student making the request
    ///
    /// Response body is a list of [CohortWithCourses] encoded in JSON.
    pub async fn cohorts(
        StudentId(student_id): StudentId,
        State(ServerState {
            database: DatabaseState(ref database),
            ..
        }): State<ServerState>,
        Json(cohort_ids): Json<Vec<RowId>>,
    ) -> impl IntoResponse {
        cohort_ids
            .into_iter()
            .map(|cohort_id| cohort(student_id, database.clone(), cohort_id))
            .collect::<tokio::task::JoinSet<_>>()
            .join_all()
            .await
            .into_iter()
            .collect::<Result<Vec<_>, _>>()
            .map_err(error_handler)
            .map(Json)
    }
}
pub use cohort::cohorts;

/// Module to bundle items relating to queries relating to courses
mod course {
    use super::*;
    /// Core course information, directly corresponding to a row in `Course` in the database
    #[derive(Serialize)]
    #[serde(rename_all = "camelCase")]
    struct Course {
        /// The ID of this course
        course_id: RowId,
        /// The name of this course
        name: String,
        /// The language being learnt
        target_language: String,
        /// The language the student is assumed to already know
        home_language: String,
        /// The number of tiers this course is divided into
        tier_count: i64,
    }

    /// A list of these are returned in JSON as the body of [courses]
    #[derive(Serialize)]
    #[serde(rename_all = "camelCase")]
    struct CourseWithTopics {
        #[serde(flatten)]
        /// Core course information, directly corresponding to a row in `Course` in the database
        course: Course,
        /// A list of topic IDs on this course, corresponding to rows in `Topic`
        topics: Vec<RowId>,
    }
    /// Returns information about a single course
    ///
    /// Includes checks that this student studies this course
    async fn course(
        student_id: RowId,
        database: Pool<Sqlite>,
        course_id: RowId,
    ) -> Result<CourseWithTopics, sqlx::Error> {
        sqlx::query_scalar!(
            r#"
            select 0
            from CohortStudent
                join CohortCourse on CohortCourse.cohort_id = CohortStudent.cohort_id
            where
                CohortStudent.student_id = ?1
            and CohortCourse.course_id = ?2
            "#,
            student_id,
            course_id,
        )
        .fetch_one(&database)
        .await?;
        tokio::try_join!(
            async {
                sqlx::query_as!(
                    Course,
                    r#"
                    select
                        course_id
                      , name
                      , target_language
                      , home_language
                      , tier_count
                    from Course
                        where course_id = ?
                    "#,
                    course_id
                )
                .fetch_one(&database)
                .await
            },
            async {
                sqlx::query_scalar!(
                    r#"
                    select topic_id as 'topic_id: RowId'
                    from Topic where course_id = ?
                    "#,
                    course_id,
                )
                .fetch_all(&database)
                .await
            }
        )
        .map(|(course, topics)| CourseWithTopics { course, topics })
    }
    /// Handler for `/api/data/courses`
    ///
    /// Return information about the requested courses,
    /// which must be a subset of the courses studied by this student
    ///
    /// Response body is a list of [CourseWithTopics] serialized in JSON
    pub async fn courses(
        StudentId(student_id): StudentId,
        State(ServerState {
            database: DatabaseState(ref database),
            ..
        }): State<ServerState>,
        Json(course_ids): Json<Vec<RowId>>,
    ) -> impl IntoResponse {
        course_ids
            .into_iter()
            .map(|course_id| course(student_id, database.clone(), course_id))
            .collect::<tokio::task::JoinSet<_>>()
            .join_all()
            .await
            .into_iter()
            .collect::<Result<Vec<_>, _>>()
            .map_err(error_handler)
            .map(Json)
    }
}
pub use course::courses;

/// Module to bundle items relating to queries relating to courses
mod topic {
    use super::*;

    /// Core topic information, directly corresponding to a row in `Topic` in the database
    #[derive(Serialize)]
    #[serde(rename_all = "camelCase")]
    struct Topic {
        /// The ID of this topic
        topic_id: RowId,
        /// The ID of the course this topic belongs to
        course_id: RowId,
        /// The name of this topic
        name: String,
    }

    /// A list of these are returned in JSON as the body of [courses]
    #[derive(Serialize)]
    #[serde(rename_all = "camelCase")]
    struct TopicWithWords {
        #[serde(flatten)]
        /// Core topic information, directly corresponding to a row in `Topic` in the database
        topic: Topic,
        ///  a list of word IDs in this topic, but only words with tier less than or equal to
        ///  `loaded_to_tier`
        words: Vec<RowId>,
        /// The maximum tier this topic is loaded for.
        ///
        /// If this is `None`, then `words` will be all the words in this topic,
        /// however if this is `Some(x)` then only words with tier less than or equal to `x`
        /// are included in `words`
        loaded_to_tier: Option<i64>,
    }

    /// The request format for `/api/data/topics`
    ///
    /// The request body is expected and required to be JSON with this structure
    #[derive(Deserialize)]
    #[serde(rename_all = "camelCase")]
    pub struct TopicsQuery {
        /// The maximum tier to load words up to
        tier: Option<i64>,
        /// A list of topic IDs to load information for
        topics: Vec<RowId>,
    }
    /// Returns information about a single topic
    ///
    /// Includes checks that this student studies this topic
    async fn topic(
        student_id: RowId,
        database: Pool<Sqlite>,
        topic_id: RowId,
        tier: Option<i64>,
    ) -> Result<TopicWithWords, sqlx::Error> {
        tokio::try_join!(
            async {
                sqlx::query_as!(
                    Topic,
                    r#"
                    select
                        Topic.topic_id
                      , Topic.course_id
                      , Topic.name
                    from Topic
                        join CohortCourse on CohortCourse.course_id = Topic.course_id
                        join CohortStudent on CohortStudent.cohort_id = CohortCourse.cohort_id
                    where
                        CohortStudent.student_id = ?1
                    and Topic.topic_id = ?2
                    "#,
                    student_id,
                    topic_id,
                )
                .fetch_one(&database)
                .await
            },
            async {
                sqlx::query_scalar!(
                    r#"
                    select word_id as 'word_id: RowId'
                    from Word
                    where
                        topic_id = ?1
                    and ifnull(tier <= ?2, true)
                    "#,
                    topic_id,
                    tier,
                )
                .fetch_all(&database)
                .await
            }
        )
        .map(|(topic, words)| TopicWithWords {
            topic,
            words,
            loaded_to_tier: tier,
        })
    }
    /// Handler for `/api/data/topics`
    ///
    /// Request must be a POST request, with body serialized as JSON,
    /// and conforming to [TopicsQuery]
    ///
    /// Returns information about the requested courses,
    /// which must be a subset of the courses studied by this student
    ///
    /// Response body is a list of [TopicWithWords] serialized in JSON
    pub async fn topics(
        StudentId(student_id): StudentId,
        State(ServerState {
            database: DatabaseState(ref database),
            ..
        }): State<ServerState>,
        Json(query): Json<TopicsQuery>,
    ) -> impl IntoResponse {
        query
            .topics
            .into_iter()
            .map(|topic_id| topic(student_id, database.clone(), topic_id, query.tier))
            .collect::<tokio::task::JoinSet<_>>()
            .join_all()
            .await
            .into_iter()
            .collect::<Result<Vec<_>, _>>()
            .map_err(error_handler)
            .map(Json)
    }
}
pub use topic::topics;

/// Module to bundle items relating to queries relating to words
mod word {
    use super::*;

    #[derive(Serialize)]
    #[serde(rename_all = "camelCase")]
    /// Fields directly correspond to a row in `Word` in the database
    struct Word {
        /// The ID of this word
        word_id: RowId,
        /// The ID of the topic this word is from
        topic_id: RowId,
        /// The word in the target language (the language being learnt)
        headword: String,
        /// A translation of the headword in the home language (a language the student already
        /// knows)
        translation: String,
        /// The minimum tier for students that need to know this word.
        ///
        /// For example a word only needed by higher tier students on a particular course will have
        /// this set to 1, as higher tier students have their tier set to 1.
        tier: i64,
        /// The part of speech this word is from, e.g. noun, adjective, adverb, pronoun.
        ///
        /// This is not applicable to every word and I only include this because some of my testing
        /// data includes this.
        ///
        /// In future though this may well be used in some way.
        part_of_speech: Option<String>,
    }

    /// Returns information about a single word
    ///
    /// Includes checks that this student studies a course that includes this word.
    ///
    /// This does not check that the tier of the word is low enough that the student would need to
    /// study it
    async fn word(
        student_id: RowId,
        database: Pool<Sqlite>,
        word_id: RowId,
    ) -> Result<Word, sqlx::Error> {
        sqlx::query_as!(
            Word,
            r#"
            select
                Word.word_id
              , Word.topic_id
              , Word.headword
              , Word.translation
              , Word.tier
              , Word.part_of_speech
            from Word
                join Topic on Topic.topic_id = Word.topic_id
                join CohortCourse on CohortCourse.course_id = Topic.course_id
                join CohortStudent on CohortStudent.student_id = ?1
            where word_id = ?2
            "#,
            student_id,
            word_id,
        )
        .fetch_one(&database)
        .await
    }

    /// Handler for `/api/data/topics`
    ///
    /// Request must be a POST request, with body serialized as JSON,
    /// which consists of a list of IDs of words to load information about
    ///
    /// Returns information about the requested words
    ///
    /// Response body is a list of [Word] serialized in JSON
    pub async fn words(
        StudentId(student_id): StudentId,
        State(ServerState {
            database: DatabaseState(ref database),
            ..
        }): State<ServerState>,
        Json(word_ids): Json<Vec<RowId>>,
    ) -> impl IntoResponse {
        word_ids
            .into_iter()
            .map(|word_id| word(student_id, database.clone(), word_id))
            .collect::<tokio::task::JoinSet<_>>()
            .join_all()
            .await
            .into_iter()
            .collect::<Result<Vec<_>, _>>()
            .map_err(error_handler)
            .map(Json)
    }
}
pub use word::words;

/// Module to bundle items relating to queries relating to progress
mod progress {
    use super::*;

    /// Fields directly correspond to a row in `StudentProgress` in the database
    #[derive(Serialize, Deserialize)]
    #[serde(rename_all = "camelCase")]
    pub struct Progress {
        /// The ID of the student whose progress this refers to
        student_id: RowId,
        /// The ID of the word this progress refers to
        word_id: RowId,
        /// Ease factor, as defined by the learning model
        ///
        /// Rougly represents how easy the student is finding it to remember the word
        ease_factor: f64,
        /// Test interval, as defined by the learning model
        ///
        /// Represents how long after the last test the next test is due
        test_interval: f64,
        /// Last test, as defined by the learning model
        ///
        /// Unix timestamp when the word was last tested
        last_test: Option<f64>,
    }

    /// Returns the progress of one student on one word
    ///
    /// This does not perform any checks that this particular student needs to know that word.
    ///
    /// If there is currently no progress recorded in the database for this word,
    /// this will return the default progress for words which have not been studied before.
    async fn single_progress(
        student_id: RowId,
        database: Pool<Sqlite>,
        word_id: RowId,
    ) -> Result<Progress, sqlx::Error> {
        sqlx::query_as!(
            Progress,
            r#"
            select
                Target.student_id as 'student_id!: RowId'
              , Target.word_id as 'word_id!: RowId'
              , coalesce(ease_factor, 2.0) as ease_factor
              , coalesce(test_interval, 24.0 * 60.0 * 60.0) as test_interval
              , last_test
            from (select
                ?1 as student_id
              , ?2 as word_id
            ) as Target
                left outer join StudentProgress
                on
                    StudentProgress.student_id = Target.student_id
                and StudentProgress.word_id = Target.word_id
            "#,
            student_id,
            word_id,
        )
        .fetch_one(&database)
        .await
    }

    /// Handler for `/api/data/progress`
    ///
    /// Request must be a POST request, with body serialized as JSON,
    /// which consists of a list of IDs of words to load the progress for.
    ///
    /// the student is inferred from the access token used to make the request.
    ///
    /// Returns the progress data for the requested words
    ///
    /// Response body is a list of [Progress] serialized in JSON
    pub async fn progress(
        StudentId(student_id): StudentId,
        State(ServerState {
            database: DatabaseState(ref database),
            ..
        }): State<ServerState>,
        Json(word_ids): Json<Vec<RowId>>,
    ) -> impl IntoResponse {
        word_ids
            .into_iter()
            .map(|word_id| single_progress(student_id, database.clone(), word_id))
            .collect::<tokio::task::JoinSet<_>>()
            .join_all()
            .await
            .into_iter()
            .collect::<Result<Vec<_>, _>>()
            .map_err(error_handler)
            .map(Json)
    }

    /// Update the database with new progress data for a single word
    ///
    /// This doesn't use any kind of deltas, simply overwriting previous data with the newly
    /// provided data.
    async fn push_change(database: Pool<Sqlite>, change: Progress) -> Result<(), sqlx::Error> {
        sqlx::query!(
            r#"
            insert or replace into StudentProgress (
                student_id
              , word_id
              , ease_factor
              , test_interval
              , last_test
            )
            values (?, ?, ?, ?, ?)
            "#,
            change.student_id,
            change.word_id,
            change.ease_factor,
            change.test_interval,
            change.last_test
        )
        .execute(&database)
        .await
        .map(|_| ())
    }

    /// Handler for `/api/progress/push`
    ///
    /// Request must be a POST request, with body serialized as JSON,
    /// which consists of a list of objects conforming to [Progress]
    ///
    /// Includes a check that each progress update is for the student the access token used to make
    /// the request belongs to.
    pub async fn push_progress(
        StudentId(student_id): StudentId,
        State(ServerState {
            database: DatabaseState(ref database),
            ..
        }): State<ServerState>,
        Json(changes): Json<Vec<Progress>>,
    ) -> impl IntoResponse {
        if !changes.iter().all(|change| change.student_id == student_id) {
            return StatusCode::BAD_REQUEST;
        }
        changes
            .into_iter()
            .map(|change| push_change(database.clone(), change))
            .collect::<tokio::task::JoinSet<_>>()
            .join_all()
            .await
            .into_iter()
            .collect::<Result<Vec<_>, _>>()
            .map_err(error_handler)
            .err()
            .unwrap_or_default()
    }
}
pub use progress::{progress, push_progress};
