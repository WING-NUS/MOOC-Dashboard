import sqlite3
import yaml

with open('config.yml') as f:
    config = yaml.load(f)
dbPath = config['dbPath']
db1Path = config['db1Path']
db2Path = config['db2Path']
f.close()

conn = sqlite3.connect(dbPath)
conn.text_factory = str
c = conn.cursor()


"""
Create tables for the merged database: user, thread and post.
:param conn: connection to target database
:param c: cursor of the connection
:return:
"""

#***********************************for users******************************#
c.execute('drop table if EXISTS user')
c.execute('''CREATE TABLE `user` \
( \
'photoUrl' TEXT, \
`courseId` TEXT, \
`userId` INTEGER, \
`id` TEXT, \
`learnerId` INTEGER, \
`courseRole` TEXT, \
`fullName` TEXT, \
'externalUserId' TEXT \
); ''')
# ***********************************for threads******************************#
c.execute('drop table if EXISTS thread')
c.execute('''CREATE TABLE `thread` \
('answerBadge' TEXT, \
'hasResolved' INTEGER, \
'instReplied' INTEGER, \
'totalAnswerCount' INTEGER, \
'isFollowing' INTEGER, \
'forumId' TEXT, \
`lastAnsweredAt` INTEGER, \
`topLevelAnswerCount` INTEGER, \
`isFlagged` INTEGER, \
'lastAnsweredBy' INTEGER, \
'state' TEXT, \
'followCount' INTEGER, \
'title' TEXT, \
'content' TEXT, \
'viewCount' INTEGER, \
'sessionId' TEXT, \
'creatorId' INTEGER, \
'isUpvoted' INTEGER, \
'id' TEXT, \
'courseId' TEXT, \
'threadId' TEXT, \
'createdAt' INTEGER, \
'upvoteCount' INTEGER \
); \
''')
# ***********************************for posts******************************#
c.execute('drop table if EXISTS post')
c.execute('''CREATE TABLE `post` \
('parentForumAnswerId' TEXT, \
'forumQuestionId' TEXT, \
'isFlagged' INTEGER, \
'order' INTEGER, \
'content' TEXT, \
'state' BLOB, \
'childAnswerCount' INTEGER, \
'creatorId' INTEGER, \
'isUpvoted' INTEGER, \
'id' TEXT, \
'courseId' TEXT, \
'postId' TEXT, \
'createdAt' INTEGER, \
'upvoteCount' INTEGER \
); \
''')



#***********************************merge users******************************#
"""Merge user tables from different databases into this merged table."""
# Set up connection to source database
conn_temp = sqlite3.connect(db1Path)
conn_temp.text_factory = str
c_temp = conn.cursor()

# Get the contents from one database
c_temp.execute('''SELECT photoUrl, courseId, userId, id, learnerId, courseRole, fullName, externalUserId \
          FROM user ;''')
output = c_temp.fetchall()   # Returns the results as a list.
print(output)

# Insert those contents into another table.
for row in output:
    c.execute('''INSERT INTO user VALUES \
          (photoUrl, \
          courseId, \
          userId, \
          id, \
          learnerId, \
          courseRole, \
          fullName, \
          externalUserId \
          ) \
           ;''', row)

conn.commit()
conn_temp.close()

# Set up connection to source database
conn_temp = sqlite3.connect(db2Path)
conn_temp.text_factory = str
c_temp = conn.cursor()

# Get the contents from one database
c_temp.execute('''SELECT photoUrl, courseId, userId, id, learnerId, courseRole, fullName, externalUserId \
          FROM user ;''')
output = c_temp.fetchall()   # Returns the results as a list.

# Insert those contents into another table.
for row in output:
    c.execute('''INSERT INTO user VALUES \
          (photoUrl, \
          courseId, \
          userId, \
          id, \
          learnerId, \
          courseRole, \
          fullName, \
          externalUserId \
          ) \
           ;''', row)

conn.commit()
conn_temp.close()

# #***********************************merge threads******************************#
# """Merge thread tables from different databases into this merged table."""
#
# c.execute('''INSERT INTO thread
#           (answerBadge, \
#           hasResolved, \
#           instReplied, \
#           totalAnswerCount, \
#           isFollowing, \
#           forumId, \
#           lastAnsweredAt, \
#           topLevelAnswerCount, \
#           isFlagged, \
#           lastAnsweredBy, \
#           state, \
#           followCount, \
#           title, \
#           content, \
#           viewCount, \
#           sessionId, \
#           creatorId, \
#           isUpvoted, \
#           id, \
#           courseId, \
#           threadId, \
#           createdAt, \
#           upvoteCount \
#           ) \
#           SELECT answerBadge, hasResolved, instReplied, totalAnswerCount, isFollowing, \
#           forumId, lastAnsweredAt, topLevelAnswerCount, isFlagged, lastAnsweredBy, \
#           state, followCount, title, content, viewCount, sessionId, creatorId, \
#           isUpvoted, id, courseId, threadId, createdAt, upvoteCount \
#           FROM coursera1.thread ;''')
#
# c.execute('''INSERT INTO thread
#           (answerBadge, \
#           hasResolved, \
#           instReplied, \
#           totalAnswerCount, \
#           isFollowing, \
#           forumId, \
#           lastAnsweredAt, \
#           topLevelAnswerCount, \
#           isFlagged, \
#           lastAnsweredBy, \
#           state, \
#           followCount, \
#           title, \
#           content, \
#           viewCount, \
#           sessionId, \
#           creatorId, \
#           isUpvoted, \
#           id, \
#           courseId, \
#           threadId, \
#           createdAt, \
#           upvoteCount \
#           ) \
#           SELECT answerBadge, hasResolved, instReplied, totalAnswerCount, isFollowing, \
#           forumId, lastAnsweredAt, topLevelAnswerCount, isFlagged, lastAnsweredBy, \
#           state, followCount, title, content, viewCount, sessionId, creatorId, \
#           isUpvoted, id, courseId, threadId, createdAt, upvoteCount \
#           FROM coursera2.thread ;''')
#
# #***********************************merge posts******************************#
# """Merge merge tables from different databases into this merged table."""
#
# c.execute('''INSERT INTO thread
#           (parentForumAnswerId, \
#           forumQuestionId, \
#           isFlagged, \
#           order, \
#           content, \
#           state, \
#           childAnswerCount, \
#           creatorId, \
#           isUpvoted, \
#           id, \
#           courseId, \
#           postId, \
#           createdAt, \
#           upvoteCount \
#           ) \
#           SELECT parentForumAnswerId, forumQuestionId, isFlagged, order, content, \
#           state, childAnswerCount, creatorId, isUpvoted, id, courseId, postId, \
#           createdAt, upvoteCount \
#           FROM coursera1.post ;''')
#
# c.execute('''INSERT INTO thread
#           (parentForumAnswerId, \
#           forumQuestionId, \
#           isFlagged, \
#           order, \
#           content, \
#           state, \
#           childAnswerCount, \
#           creatorId, \
#           isUpvoted, \
#           id, \
#           courseId, \
#           postId, \
#           createdAt, \
#           upvoteCount \
#           ) \
#           SELECT parentForumAnswerId, forumQuestionId, isFlagged, order, content, \
#           state, childAnswerCount, creatorId, isUpvoted, id, courseId, postId, \
#           createdAt, upvoteCount \
#           FROM coursera2.post ;''')

conn.commit()
conn.close()
