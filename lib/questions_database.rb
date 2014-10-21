require 'sqlite3'
require 'singleton'
require 'debugger'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.results_as_hash = true
    self.type_translation = true
  end

end

class User

  attr_accessor :id, :fname, :lname

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

end

class Question
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
end

class Follower
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

end

class Reply
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

class QuestionLike
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

end