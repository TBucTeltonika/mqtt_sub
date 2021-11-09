#include <stdio.h>
#include <stdlib.h>
#include <sqlite3.h>
#include <time.h>

//Get database resources. If database doesn't exist it is initialized.
sqlite3* get_db();
//Get Sqlite statment. For insert only.
sqlite3_stmt* get_stmt();
//Insert date/topic/payload into database. ID assigned automatically.
int insert_into_db( char* topic, char* payload);
//Call when finished to free resources.
int free_db_resources();