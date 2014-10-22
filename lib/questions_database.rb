require 'sqlite3'
require 'singleton'
require 'debugger'
require 'active_support/inflector'

class DatabaseSaver
  def self.all
    query = <<-SQL
      SELECT
        *
      FROM
        #{self.to_s.tableize}
    SQL
    like_hashes = QuestionsDatabase.instance.execute(query)
    like_hashes.map do |like|
      self.new(like)
    end
  end

  def save
    if @id.nil?
      insert
    else
      update
    end
  end

  def insert
    i_vars = self.instance_variables
    i_vars.delete(:@id)
    i_var_names = i_vars.map { |i_var| (i_var.to_s)[1..-1] }
    i_var_values = i_vars.map { |i_var| self.instance_variable_get(i_var) }
    insert_query = <<-SQL
      INSERT INTO
        #{self.class.to_s.tableize}(#{i_var_names.join(",")})
      VALUES
      (#{(['?'] * i_vars.length).join(",")})
    SQL
    QuestionsDatabase.instance.execute(insert_query, *i_var_values)
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    i_vars = self.instance_variables
    i_vars.delete(:@id)
    i_var_names = i_vars.map { |i_var| (i_var.to_s)[1..-1] }
    i_var_values = i_vars.map { |i_var| self.instance_variable_get(i_var) }
    columns_to_set = i_var_names.map { |name| "#{name} = ?" }
    update_query = <<-SQL
      UPDATE
        #{self.class.to_s.tableize}
      SET
        #{columns_to_set.join(",")}
      WHERE
        id = ?
    SQL
    QuestionsDatabase.instance.execute(update_query, *i_var_values, @id)
  end

end

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.results_as_hash = true
    self.type_translation = true
  end

end

class User < DatabaseSaver

  attr_accessor :fname, :lname
  attr_reader :id

  def initialize(options = {})
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def self.find_by_id(user_id)
    query =  <<-SQL
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?
    SQL
    user_hash = QuestionsDatabase.instance.execute(query, user_id)[0]
    self.new(user_hash)
  end

  def self.find_by_name(fname, lname)
    query =  <<-SQL
      SELECT
        *
      FROM
        users
      WHERE
        users.fname = ?
        AND
        users.lname = ?
    SQL
    user_hash = QuestionsDatabase.instance.execute(query, fname, lname)[0]
    self.new(user_hash)
  end

  def authored_questions
    query = <<-SQL
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL
    questions = QuestionsDatabase.instance.execute(query, @id)
    questions.map do |question|
      Question.new(question)
    end
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    Follower.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    query = <<-SQL
    SELECT
      ( SUM(total_likes.likes) / CAST(COUNT(*) as FLOAT) ) AS karma
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
      questions.user_id
    HAVING
      questions.user_id = ?
    SQL

    karma = QuestionsDatabase.instance.execute(query, @id)[0]['karma']
  end

end

class Question < DatabaseSaver
  attr_reader :id, :user_id
  attr_accessor :title, :body

  def initialize(options = {})
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end

  def self.find_by_id(question_id)
    query =  <<-SQL
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    question_hash = QuestionsDatabase.instance.execute(query, question_id)[0]
    self.new(question_hash)
  end

  def self.find_by_author_id(author_id)
    query =  <<-SQL
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL
    questions = QuestionsDatabase.instance.execute(query, author_id)
    questions.map do |question|
      self.new(question)
    end
  end

  def author
    User.find_by_id(@user_id)
  end

  def replies
    query =  <<-SQL
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    replies = QuestionsDatabase.instance.execute(query, @id)
    replies.map do |reply|
      Reply.new(reply)
    end
  end

  def followers
    Follower.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    Follower.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
end

class Follower < DatabaseSaver
  attr_reader :id, :user_id, :question_id

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.find_by_id(follower_id)
    query =  <<-SQL
      SELECT
        *
      FROM
        followers
      WHERE
        id = ?
    SQL
    follower_hash = QuestionsDatabase.instance.execute(query, follower_id)[0]
    self.new(follower_hash)
  end

  def self.followers_for_question_id(question_id)
    query =  <<-SQL
      SELECT
        users.id AS id, fname, lname
      FROM
        users
      JOIN
        followers
      ON
        users.id = followers.user_id
      WHERE
        followers.question_id = ?
    SQL
    users_hash = QuestionsDatabase.instance.execute(query, question_id)
    users_hash.map do |user|
      User.new(user)
    end

  end

  def self.followed_questions_for_user_id(user_id)
    query =  <<-SQL
      SELECT
      *
      FROM
        questions
      JOIN
        followers
      ON
        questions.id = followers.question_id
      WHERE
        followers.user_id = ?
    SQL
    questions_hash = QuestionsDatabase.instance.execute(query, user_id)
    questions_hash.map do |question|
      Question.new(question)
    end
  end

  def self.most_followed_questions(n)
    query = <<-SQL
      SELECT
        question_id AS id,
        title,
        body,
        questions.user_id
      FROM
        followers
      JOIN
        questions
      ON
        questions.id = followers.question_id
      GROUP BY
        question_id
      ORDER BY
        COUNT(question_id) DESC
      LIMIT
        ?
    SQL

    questions = QuestionsDatabase.instance.execute(query, n)
    questions.map do |question|
      Question.new(question)
    end
  end

end

class Reply < DatabaseSaver
  attr_reader :id, :user_id, :question_id, :reply_id, :body

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
    @reply_id = options['reply_id']
    @body = options['body']
  end

  def self.find_by_id(own_id)
    query =  <<-SQL
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    reply_hash = QuestionsDatabase.instance.execute(query, own_id)[0]
    self.new(reply_hash)
  end

  def self.find_by_question_id(question_id)
    Question.find_by_id(question_id).replies
  end

  def self.find_by_user_id(user_id)
    query = <<-SQL
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    replies = QuestionsDatabase.instance.execute(query, user_id)
    replies.map do |reply|
      Reply.new(reply)
    end
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@reply_id) unless @reply_id.nil?
  end

  def child_replies
    query = <<-SQL
      SELECT
        *
      FROM
        replies
      WHERE
        reply_id = ?
    SQL
    replies = QuestionsDatabase.instance.execute(query, @id)
    replies.map do |reply|
      Reply.new(reply)
    end
  end

end

class QuestionLike < DatabaseSaver
  attr_reader :id, :user_id, :question_id

  def initialize(options = {})
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.find_by_id(question_like_id)
    query =  <<-SQL
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    question_like_hash =
      QuestionsDatabase.instance.execute(query, question_like_id)[0]
    self.new(question_like_hash)
  end

  def self.likers_for_question_id(question_id)
    query =  <<-SQL
      SELECT
        question_likes.user_id AS id, fname, lname
      FROM
        question_likes
      JOIN
        users
      ON
       users.id = question_likes.user_id
      WHERE
        question_id = ?
    SQL
    likers = QuestionsDatabase.instance.execute(query, question_id)
    likers.map do |liker|
      User.new(liker)
    end
  end

  def self.num_likes_for_question_id(question_id)
    query = <<-SQL
    SELECT
      COUNT(*) AS likes
    FROM
      question_likes
    WHERE
      question_id = ?
    GROUP BY
      question_id
    SQL
    likes = QuestionsDatabase.instance.execute(query, question_id)
    likes[0]['likes']
  end

  def self.liked_questions_for_user_id(user_id)
    query =  <<-SQL
      SELECT
        questions.id AS id,
        questions.body AS body,
        questions.title AS title,
        questions.user_id AS user_id
      FROM
        question_likes
      JOIN
        questions
      ON
       questions.id = question_likes.question_id
      WHERE
        question_likes.user_id = ?
    SQL
    liked_questions = QuestionsDatabase.instance.execute(query, user_id)
    liked_questions.map do |liked_question|
      Question.new(liked_question)
    end
  end

  def self.most_liked_questions(n)
    query = <<-SQL
      SELECT
        question_id AS id,
        title,
        body,
        questions.user_id as user_id
      FROM
        question_likes
      JOIN
        questions
      ON
        question_likes.question_id = questions.id
      GROUP BY
        question_id
      ORDER BY
        COUNT(question_id) DESC
      LIMIT
        ?
    SQL

    questions = QuestionsDatabase.instance.execute(query, n)
    questions.map do |question|
      Question.new(question)
    end
  end
end