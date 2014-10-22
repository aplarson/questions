SELECT
  SUM(total_likes.likes) / COUNT(*)
FROM
  questions
LEFT OUTER JOIN
  (SELECT
    question_id, COUNT(*) AS likes
  FROM
    question_likes
  GROUP BY
    question_id) AS total_likes
ON
  questions.id = total_likes.question_id
GROUP BY
  questions.user_id;