import pyodbc
import datetime

# Database Configuration
DB_CONFIG = {
    'server': 'localhost',
    'database': 'Floria_2',
    'username': 'sa',
    'password': 'YourSecurePassword123!', # Default from docker-compose, change if needed
    'driver': '{ODBC Driver 17 for SQL Server}'
}

OUTPUT_FILE = 'database_dump.sql'

def get_connection():
    conn_str = f"DRIVER={DB_CONFIG['driver']};SERVER={DB_CONFIG['server']};DATABASE={DB_CONFIG['database']};UID={DB_CONFIG['username']};PWD={DB_CONFIG['password']};TrustServerCertificate=yes;"
    return pyodbc.connect(conn_str)

def generate_insert_statements(cursor, table_name):
    cursor.execute(f"SELECT * FROM {table_name}")
    columns = [column[0] for column in cursor.description]
    rows = cursor.fetchall()
    
    statements = []
    if rows:
        statements.append(f"\n-- Data for {table_name}")
        statements.append(f"SET IDENTITY_INSERT {table_name} ON;")
        
        for row in rows:
            values = []
            for val in row:
                if val is None:
                    values.append("NULL")
                elif isinstance(val, (int, float)):
                    values.append(str(val))
                elif isinstance(val, bool):
                    values.append('1' if val else '0')
                elif isinstance(val, (datetime.date, datetime.datetime)):
                    values.append(f"'{val.isoformat()}'")
                else:
                    values.append(f"N'{str(val).replace("'", "''")}'")
            
            val_str = ", ".join(values)
            col_str = ", ".join([f"[{c}]" for c in columns])
            statements.append(f"INSERT INTO {table_name} ({col_str}) VALUES ({val_str});")
            
        statements.append(f"SET IDENTITY_INSERT {table_name} OFF;")
    return statements

def main():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        print(f"Connected to {DB_CONFIG['database']}...")
        
        # Get all tables
        cursor.execute("SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'")
        tables = cursor.fetchall()
        
        with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
            f.write(f"-- Database Dump for {DB_CONFIG['database']}\n")
            f.write(f"-- Generated at {datetime.datetime.now()}\n\n")
            
            # Disable constraints globally
            f.write("EXEC sp_msforeachtable \"ALTER TABLE ? NOCHECK CONSTRAINT all\";\n")
            
            for schema, table in tables:
                full_table_name = f"[{schema}].[{table}]"
                if table != 'sysdiagrams':
                    print(f"Exporting data from {full_table_name}...")
                    try:
                        inserts = generate_insert_statements(cursor, full_table_name)
                        for stmt in inserts:
                            f.write(stmt + "\n")
                    except Exception as e:
                        print(f"Skipping {full_table_name} (Error: {e})")

            # Re-enable constraints
            f.write("\nEXEC sp_msforeachtable \"ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all\";\n")
            
        print(f"\nDatabase exported successfully to {OUTPUT_FILE}")
        print("You can share this file with others to replicate your data.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals(): conn.close()

if __name__ == "__main__":
    main()
