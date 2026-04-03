//! Manages database connection and provides some helpful types for working with SQLite
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use sqlx::{Pool, Sqlite, Type, sqlite::SqliteConnectOptions};

/// In SQLite, every table implicitly has a 64-bit signed integer row id column If the row id is
/// encoded as a number in JSON, it will be converted to a 64-bit float when decoded with
/// JSON.parse, so it must be parsed into a string until it can be converted into a more suitable
/// format. On most browsers this can be done using the reviver parameter on JSON.parse,
/// however this isn't supported widely enough.
///
/// So instead I've created a wrapper type that serializes an i64 to a string
#[derive(Type, Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[sqlx(transparent)]
pub struct RowId(pub i64);

impl Serialize for RowId {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        serializer.serialize_str(self.0.to_string().as_str())
    }
}
impl<'de> Deserialize<'de> for RowId {
    fn deserialize<D: Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        // Largely copied from the serde_aux crate
        #[derive(Deserialize)]
        #[serde(untagged)]
        enum StringOrInt {
            String(String),
            Int(i64),
        }
        match StringOrInt::deserialize(deserializer)? {
            StringOrInt::String(s) => s
                .parse::<i64>()
                .map_err(serde::de::Error::custom)
                .map(RowId),
            StringOrInt::Int(i) => Ok(RowId(i)),
        }
    }
}
impl From<i64> for RowId {
    fn from(value: i64) -> Self {
        Self(value)
    }
}

/// The axum state used to store the global SQLite connection pool.
#[derive(Clone)]
pub struct DatabaseState(pub Pool<Sqlite>);

impl Default for DatabaseState {
    fn default() -> Self {
        let opts = SqliteConnectOptions::new()
            .filename("data/database.sqlite3")
            .optimize_on_close(true, None)
            .analysis_limit(400);
        let pool = Pool::connect_lazy_with(opts);
        let connection = pool.acquire();
        // harden the database a little bit by limiting blob sizes
        tokio::spawn(async move {
            let mut connection: sqlx::pool::PoolConnection<Sqlite> =
                connection.await.expect("Failed to get connection");
            let raw = connection
                .lock_handle()
                .await
                .expect("Falied to lock handle")
                .as_raw_handle();
            unsafe {
                libsqlite3_sys::sqlite3_limit(
                    raw.as_ptr(),
                    libsqlite3_sys::SQLITE_LIMIT_LENGTH,
                    1024 * 1024,
                );
            }
        });
        Self(pool)
    }
}
