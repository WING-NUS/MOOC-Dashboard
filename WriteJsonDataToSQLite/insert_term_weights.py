import sqlite3
import yaml

with open('config.yml') as f:
    config = yaml.load(f)
dbPath = config['dbPath']    # Now dbPath is coursera.db
termweightsdbPath = config['termweightsdbPath']
f.close()

conn = sqlite3.connect(dbPath)    # Connect to the course database
conn.row_factory = sqlite3.Row    # For reading column names from course Database
c = conn.cursor()

conn_temp = sqlite3.connect(termweightsdbPath)    # Connect to the term weight database
conn_temp.row_factory = sqlite3.Row    # For reading column names from term weight Database
conn_temp.text_factory = lambda x: str(x, 'latin1')
c_temp = conn_temp.cursor()

print("Inserting term weights ...")

"""Create tables for term weights."""
#***********************************termFreqC14inst******************************#
c.execute('drop table if EXISTS "termFreqC14inst"')
c.execute('''CREATE TABLE 'termFreqC14inst' \
(termid integer, threadid integer, courseid text, term text, tf integer, type text, \
stem interger, stopword integer, commentid, postid integer, ispost, \
primary key(termid,postid,commentid,threadid,courseid)); ''')
# ***********************************termFreqC14noinst******************************#
c.execute('drop table if EXISTS "termFreqC14noinst"')
c.execute('''CREATE TABLE 'termFreqC14noinst' \
(termid integer, threadid integer, courseid text, term text, tf integer, type text, \
stem interger, stopword integer, commentid, postid integer, ispost, \
primary key(termid,postid,commentid,threadid,courseid)); ''')
# ***********************************tags******************************#
c.execute('drop table if EXISTS "tags"')
c.execute('''CREATE TABLE 'tags' \
(tagid integer, tagname text, courseid integer, primary key(tagid,courseid)); ''')
# ***********************************termdf******************************#
c.execute('drop table if EXISTS "termdf"')
c.execute('''CREATE TABLE 'termdf' \
(termid integer, term text, df integer, idf real, stem integer, stopword integer,
courseid, forumid, forumname, primary key (termid,courseid,forumid)); ''')
# ***********************************termIDF******************************#
c.execute('drop table if EXISTS "termIDF"')
c.execute('''CREATE TABLE 'termIDF' \
(termid integer, term text, df integer, idf real, stem integer, stopword integer, courseid); ''')



"""Insert term weights relevant tables into the table created above"""
#***********************************termFreqC14inst******************************#
c_temp.execute('''SELECT * FROM termFreqC14inst ;''')
row_1 = c_temp.fetchone()       # Fetch column names from one course database table
columnNames = row_1.keys()    # Read column names from the course database

c_temp.execute('''SELECT * FROM termFreqC14inst ;''')
rows1 = c_temp.fetchall()     # Read all rows from Database1
rows1 = [r[0:] for r in rows1]  # Except first row in rows1 read all rows

ques = []            # Use by sqlite for inserting into table
ques = ["?"]*len(columnNames[0:])  # Generate list [?, ?, ?, ?,........till length equals length of columnNames[1:]
ques = ",".join(ques)        # Generate string "?,?,?,?,?........"
columnNames = ",".join(columnNames[0:]) # Generate string "col1, col2, col3............"

for item in rows1:        # Insert combined data into new Database3
    c.execute("INSERT INTO termFreqC14inst({0}) VALUES ({1})".format(columnNames, ques), item)

#***********************************termFreqC14noinst******************************#
c_temp.execute('''SELECT * FROM termFreqC14noinst ;''')
row_1 = c_temp.fetchone()       # Fetch column names from one course database table
columnNames = row_1.keys()    # Read column names from the course database

c_temp.execute('''SELECT * FROM termFreqC14noinst ;''')
rows1 = c_temp.fetchall()     # Read all rows from Database1
rows1 = [r[0:] for r in rows1]  # Except first row in rows1 read all rows

ques = []            # Use by sqlite for inserting into table
ques = ["?"]*len(columnNames[0:])  # Generate list [?, ?, ?, ?,........till length equals length of columnNames[1:]
ques = ",".join(ques)        # Generate string "?,?,?,?,?........"
columnNames = ",".join(columnNames[0:]) # Generate string "col1, col2, col3............"

for item in rows1:        # Insert combined data into new Database3
    c.execute("INSERT INTO termFreqC14noinst({0}) VALUES ({1})".format(columnNames, ques), item)

#***********************************tags******************************#
c_temp.execute('''SELECT * FROM tags ;''')
row_1 = c_temp.fetchone()       # Fetch column names from one course database table
columnNames = row_1.keys()    # Read column names from the course database

c_temp.execute('''SELECT * FROM tags ;''')
rows1 = c_temp.fetchall()     # Read all rows from Database1
rows1 = [r[0:] for r in rows1]  # Except first row in rows1 read all rows

ques = []            # Use by sqlite for inserting into table
ques = ["?"]*len(columnNames[0:])  # Generate list [?, ?, ?, ?,........till length equals length of columnNames[1:]
ques = ",".join(ques)        # Generate string "?,?,?,?,?........"
columnNames = ",".join(columnNames[0:]) # Generate string "col1, col2, col3............"

for item in rows1:        # Insert combined data into new Database3
    c.execute("INSERT INTO tags({0}) VALUES ({1})".format(columnNames, ques), item)

#***********************************termdf******************************#
c_temp.execute('''SELECT * FROM termdf ;''')
row_1 = c_temp.fetchone()       # Fetch column names from one course database table
columnNames = row_1.keys()    # Read column names from the course database

c_temp.execute('''SELECT * FROM termdf ;''')
rows1 = c_temp.fetchall()     # Read all rows from Database1
rows1 = [r[0:] for r in rows1]  # Except first row in rows1 read all rows

ques = []            # Use by sqlite for inserting into table
ques = ["?"]*len(columnNames[0:])  # Generate list [?, ?, ?, ?,........till length equals length of columnNames[1:]
ques = ",".join(ques)        # Generate string "?,?,?,?,?........"
columnNames = ",".join(columnNames[0:]) # Generate string "col1, col2, col3............"

for item in rows1:        # Insert combined data into new Database3
    c.execute("INSERT INTO termdf({0}) VALUES ({1})".format(columnNames, ques), item)

#***********************************termIDF******************************#
c_temp.execute('''SELECT * FROM termIDF ;''')
row_1 = c_temp.fetchone()       # Fetch column names from one course database table
columnNames = row_1.keys()    # Read column names from the course database

c_temp.execute('''SELECT * FROM termIDF ;''')
rows1 = c_temp.fetchall()     # Read all rows from Database1
rows1 = [r[0:] for r in rows1]  # Except first row in rows1 read all rows

ques = []            # Use by sqlite for inserting into table
ques = ["?"]*len(columnNames[0:])  # Generate list [?, ?, ?, ?,........till length equals length of columnNames[1:]
ques = ",".join(ques)        # Generate string "?,?,?,?,?........"
columnNames = ",".join(columnNames[0:]) # Generate string "col1, col2, col3............"

for item in rows1:        # Insert combined data into new Database3
    c.execute("INSERT INTO termIDF({0}) VALUES ({1})".format(columnNames, ques), item)



conn.commit()
conn_temp.close()
print("#Done#")
