#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-
# @Time    : 11/8/2016 8:12 PM
# @Author  : Ann
# @Site    :
# @File    : writeToSQLite.py
# @Software: PyCharm

import sqlite3
import yaml

with open('config.yml') as f:
    config = yaml.load(f)
dbPath = config['dbPath']
f.close()

conn = sqlite3.connect(dbPath)
conn.text_factory = str
c = conn.cursor()
#***********************************for users******************************#
c.execute('drop table if exists thread_new')
c.execute('drop table if exists post_new')
c.execute('drop table if exists comment_new')
c.execute('drop table if exists user_new')
c.execute('drop table if exists user_temp')
c.execute('drop table if exists forum')

# Transfer and reorganize the threads data into canonical schema which would be used in classifier api
c.execute('''CREATE TABLE thread_new ( \
id text, \
title text, \
url text, \
num_views integer, \
num_posts integer, \
has_resolved integer, \
inst_replied integer, \
is_spam integer, \
stickied integer, \
starter integer, \
last_poster integer, \
votes integer, \
courseid text, \
forumid text, \
errorflag int, \
tagids, \
docid integer, \
resolved, \
deleted, \
approved, \
posted_time integer, \
score float, \
primary key(url))''')

c.execute('''REPLACE into thread_new \
(id,title,url,num_views,num_posts,starter,last_poster,votes,courseid,forumId,errorflag,posted_time,has_resolved,inst_replied,resolved) \
select id,title,id,viewCount,totalAnswerCount,creatorId,lastAnsweredBy,upvoteCount,courseId,forumId,0,createdAt,hasResolved,instReplied,hasResolved \
from thread''')

c.execute('''UPDATE thread_new set score = 0.0''')


# Transfer and reorganize the posts data into canonical schema which would be used in classifier api
c.execute('''CREATE TABLE post_new(
id text, \
thread_id text, \
original integer, \
post_order integer, \
url text, \
post_text text, \
votes integer, \
user integer, \
post_time real, \
forumid text, \
courseid text, \
errorflag int, \
primary key(id,thread_id,forumid,courseid))''')
c.execute('''REPLACE into post_new \
(id,thread_id,original,post_order, post_text,votes,user,post_time,courseid) \
select id, forumQuestionId, 0,`order`, content,upvoteCount, creatorId,createdAt,courseId
from post where parentForumAnswerId == ''
''')  # Select useful columes from post table into a new table. The new post table will be used by Muthu's APIs.
c.execute('''REPLACE into post_new \
(id,thread_id,original, post_text,votes,user,post_time,forumid,courseid) \
select id, id, 1, content,upvoteCount, creatorId,createdAt,forumId,courseId
from thread
''')  # Select useful columes from thread table into a new table. The new post table will be used by Muthu's APIs.

# Transfer and reorganize the comments data into canonical schema which would be used in classifier api
c.execute('''CREATE TABLE comment_new(
id text, \
post_id text, \
thread_id text, \
forumid text, \
url text, \
comment_text text, \
votes integer, \
user integer, \
post_time integer, \
user_name text, \
courseid text, \
primary key(id,thread_id,forumid,courseid))''')
c.execute('''REPLACE into comment_new \
(id,post_id,thread_id, comment_text,votes,user,post_time, courseid)
select id, parentForumAnswerId, forumQuestionId, content, upvoteCount, creatorId, createdAt, courseId
from post where parentForumAnswerId != ''
''')

c.execute('''CREATE TABLE user_temp (
id integer, \
full_name text, \
anonymous integer, \
user_profile text, \
user_title text, \
postid text, \
threadid text, \
forumid text, \
courseid text \
)''')

c.execute('''REPLACE into user_temp(id, full_name, user_profile, user_title, courseid)
select userid, fullName, photoUrl,  courseRole, courseId
from user
''')

c.execute('''CREATE TABLE user_new (
id integer, \
full_name text, \
anonymous integer, \
user_profile text, \
user_title text, \
postid text, \
threadid text, \
forumid text, \
courseid text \
)''')

c.execute('''CREATE TABLE forum ( \
id integer, \
forumname text, \
courseid text, \
conversation integer, \
downloaded integer, \
dataset text, \
numthreads integer, \
numinter integer, \
primary key(id, courseid))''')
# c.execute('''REPLACE into forum \
# (id,forumname,courseid) \
# select id,'lecture',courseId \
# from thread''')
c.execute('''REPLACE into forum \
(id,forumname,courseid) \
select forumId,'Lecture',courseId \
from thread''')

'''Create table post2, post3, comment2, comment3 for make_noinstructor_corpus.pl at step 6'''
c.execute('''CREATE TABLE post2 ( \
          id text, \
          thread_id text, \
          original integer, \
          post_order integer, \
          url text, \
          post_text text, \
          votes integer, \
          user integer, \
          post_time real, \
          forumid text, \
          courseid text \
          )''')
c.execute('''CREATE TABLE post3 ( \
          id text, \
          thread_id text, \
          original integer, \
          post_order integer, \
          url text, \
          post_text text, \
          votes integer, \
          user integer, \
          post_time real, \
          forumid text, \
          courseid text \
          )''')
c.execute('''CREATE TABLE comment2 ( \
          id text, \
          post_id text, \
          thread_id text, \
          forumid text, \
          url text, \
          comment_text text, \
          votes integer, \
          user integer, \
          post_time integer, \
          user_name text, \
          courseid text \
          )''')
c.execute('''CREATE TABLE comment3 ( \
          id text, \
          post_id text, \
          thread_id text, \
          forumid text, \
          url text, \
          comment_text text, \
          votes integer, \
          user integer, \
          post_time integer, \
          user_name text, \
          courseid text \
          )''')


conn.commit()
conn.close()
