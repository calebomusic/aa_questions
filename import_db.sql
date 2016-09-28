DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users(fname, lname)
VALUES
  ('Caleb', 'Ontiveros'),
  ('Jane', 'Hauf'),
  ('Charles II', 'Prince'),
  ('Jennifer', 'Aniston'),
  ('Kush', 'Patel'),
  ('P', 'Diddy'),
  ('Mystery', 'User'),
  ('Another', 'User');

INSERT INTO
  questions(title, body, author_id)
VALUES
  ('HELP', 'I need help', 1),
  ('How old is Jennifer Aniston', 'For a friend', 2),
  ('Who', 'Is asking questions about me?', 4),
  ('Technical database question', 'how do you blah blah SQL', 3),
  ('Question', 'another question', 7);

INSERT INTO
  replies(title, body, question_id, parent_id, author_id)
VALUES
  ('Specifics?', 'Can you be a bit more specific', 1, null, 2),
  ('Answer', '45.', 2, null, 1),
  ('Just kidding', '47.', 2, 2, 1),
  ('Why', 'Are you talking about me', 2, 3, 4),
  ('Technical answer', 'SQL SQL SQL', 4, null, 5),
  ('Answer', 'another answer', 5, null, 6);

INSERT INTO
  question_likes(user_id, question_id)
VALUES
  (1, 2),
  (2, 2),
  (3, 2),
  (5, 2),
  (6, 2),
  (7, 2),
  (3, 4),
  (5, 4),
  (1, 4);

INSERT INTO
  question_follows(user_id, question_id)
VALUES
  (2, 1),
  (2, 2),
  (2, 6),
  (6, 4),
  (7, 1),
  (4,2),
  (3,2);
