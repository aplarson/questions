CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE followers (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  reply_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (reply_id) REFERENCES replies(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Ben','Henderson'), ('Andrew','Larson'), ('CJ', 'Avila');

INSERT INTO
questions (title, body, user_id)
VALUES
('Why is it so hot in here?', 'It is really hot in here. Why is that?',
  (SELECT id
  FROM users
  WHERE fname = 'Andrew')
), ('Why is it so cold in here?', 'It is really cold in here. Why is that?',
  (SELECT id
  FROM users
  WHERE fname = 'Ben')
),
('Why is it so tepid in here?', 'It is really mild in temperature here!!!', 1);

INSERT INTO
  followers (question_id, user_id)
VALUES
  (1, 3),
  (1, 1),
  (2, 2);

INSERT INTO
  replies (question_id, reply_id, user_id, body)
VALUES
  (1, NULL, 1, 'No it is very cold' ),
  (2, NULL, 2, 'It is sweltering in here'),
  (1, 1, 2, 'No it is hot!'),
  (2, 2, 1, 'I do not agree!');

INSERT INTO
 question_likes (user_id, question_id)
VALUES
  (3, 1),
  (3, 2),
  (2, 2),
  (1, 1)
 ;