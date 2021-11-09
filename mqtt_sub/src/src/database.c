#include "database.h"

#define DATABASE "/log/mqtt_sub_log.db"
#define STATEMENT_STR "INSERT INTO log (TIME, TOPIC, PAYLOAD) VALUES (?, ?, ?)"
#define TABLE_STR "CREATE TABLE IF NOT EXISTS log (id INTEGER PRIMARY KEY AUTOINCREMENT, TIME INTEGER, TOPIC TEXT, PAYLOAD TEXT);"

static int create_table(sqlite3 *db)
{
	sqlite3_stmt *stmt = NULL;
	if (sqlite3_prepare_v2(db, TABLE_STR, -1, &stmt, NULL))
	{
		printf("Error executing sql statement\n");
		sqlite3_close(db);
	}
	if (stmt != NULL)
		sqlite3_step(stmt);

	return 0;
}

sqlite3 *get_db()
{
	static sqlite3 *db = NULL;
	if (db == NULL && sqlite3_open(DATABASE, &db))
	{
		printf("Could not open the db\n");
		exit(-1);
	}
	else
		create_table(db);
	return db;
}

sqlite3_stmt *get_stmt()
{
	sqlite3_stmt *stmt = NULL;
	if (sqlite3_prepare_v2(get_db(), STATEMENT_STR, -1, &stmt, NULL))
	{
		printf("Error executing sql statement\n");
		sqlite3_close(get_db());
	}
	return stmt;
}

int insert_into_db(char *topic, char *payload)
{
	int rc = 0;
	sqlite3 *db = get_db();

	/* Prepare a statement for multiple use:*/

	sqlite3_stmt *stmt = get_stmt();

	//Get epoch date
	int date = (int)time(NULL);

	rc = sqlite3_bind_int(stmt, 1, date);
	if (rc != 0)
		TRACE_LOG(1, "sqlite3_bind_int failed. rc: %d\n", rc);

	rc = sqlite3_bind_text(stmt, 2, topic, -1, NULL);
	if (rc != 0)
		TRACE_LOG(1, "sqlite3_bind_text failed. rc: %d\n", rc);

	rc = sqlite3_bind_text(stmt, 3, payload, -1, NULL);
	if (rc != 0)
		TRACE_LOG(1, "sqlite3_bind_text2 failed. rc: %d\n", rc);

	//execute statement
	rc = sqlite3_step(stmt);
	if (rc != SQLITE_DONE)
		TRACE_LOG(1, "step failed. rc: %d\n", rc);

	return rc;
}

int free_db_resources()
{
	sqlite3_stmt *stmt = get_stmt();
	if (stmt != NULL)
		sqlite3_finalize(stmt);

	sqlite3 *db = get_db();
	if (db != NULL)
		sqlite3_close(db);
}