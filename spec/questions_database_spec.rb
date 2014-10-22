require 'questions_database'
require 'spec_helper'


describe User do
  describe "::find" do
    it "should return a single user by id" do
      expect(User.find_by_id(1).is_a?(User)).to eq(true)
      expect(User.find_by_id(1).id).to eq(1)
    end
  end

  describe "::find_by_name" do
    it "returns a single user by name" do
      user = User.find_by_name("Andrew", "Larson")
      expect(user.is_a?(User)).to eq(true)
      expect(user.fname).to eq("Andrew")
      expect(user.lname).to eq("Larson")
    end
  end

  describe "#authored_questions" do
    it "finds the questions a user has authored" do
      user = User.find_by_id(1)
      expect(user.authored_questions.is_a?(Array)).to eq(true)
      expect(user.authored_questions[0].is_a?(Question)).to eq(true)
      expect(user.authored_questions[0].user_id).to eq(1)
    end
  end

  describe "#authored_replies" do
    it "finds the replies a user has authored" do
      user = User.find_by_id(1)
      expect(user.authored_replies.is_a?(Array)).to eq(true)
      expect(user.authored_replies[0].is_a?(Reply)).to eq(true)
      expect(user.authored_replies[0].user_id).to eq(1)
    end
  end

  describe "followed questions" do
    it "returns the questions the user is following" do
      user = User.find_by_id(3)
      expect(user.followed_questions[0].id).to eq(1)
    end
  end

  describe "karma" do
    it "returns the avg karma for the user" do
      user = User.find_by_id(1)
      expect(user.average_karma).to eq(1)
    end
  end

  describe "saving" do
    describe "saving a new user" do
      it "saves the user to the database" do
        user = User.new({ 'fname' => "Jim", 'lname' => "Bob" })
        expect{user.save}.to change{User.all.length}.by(1)

      end
    end

    describe "updating an existing user" do
      it "updates the user's information" do
        user = User.find_by_name("CJ", "Avila")
        user.fname, user.lname = "Jeff", "Fiddler"
        id = user.id
        user.save
        updated_user = User.find_by_id(id)
        updated_fname, updated_lname = updated_user.fname, updated_user.lname
        expect(updated_fname).to eq("Jeff")
        expect(updated_lname).to eq("Fiddler")
        updated_user.fname, updated_user.lname = "CJ", "Avila"
        updated_user.save
      end
    end
  end

end

describe Follower do
  it "should return a single user by id" do
    expect(Question.find_by_id(1).is_a?(Question)).to eq(true)
    expect(Question.find_by_id(1).id).to eq(1)
  end

  describe "followers for question id" do
    it "returns users following the question" do
      followers = Follower.followers_for_question_id(1)
      expect(followers.all? { |follower| follower.is_a?(User) }).to eq(true)
      expect(followers[0].id).to eq(3)
    end
  end

  describe "followed_questions_for_user_id" do
    it "returns an array of questions" do
      questions = Follower.followed_questions_for_user_id(3)
      expect(questions.all? { |question| question.is_a?(Question) }).to eq(true)
      expect(questions[0].id).to eq(1)
    end
  end

  describe "most_followed_questions" do
    it "returns the most followed questions for n=1" do
      questions = Follower.most_followed_questions(1)
      expect(questions[0].id).to eq(1)
    end

    it "returns the most followed questions for greater n" do
      questions = Follower.most_followed_questions(2)
      expect(questions.length).to eq(2)
      expect(questions[0].id).to eq(1)
      expect(questions[1].id).to eq(2)
    end
  end

  describe "saving" do
    describe "saving a new follow" do
      it "saves the follow to the database" do
        follower = Follower.new({ 'user_id' => 3, 'question_id' => 2 })
        expect{follower.save}.to change{Follower.all.length}.by(1)
      end
    end
  end
end

describe Question do
  it "should return a single user by id" do
    expect(Question.find_by_id(1).is_a?(Question)).to eq(true)
    expect(Question.find_by_id(1).id).to eq(1)
  end

  describe "::find_by_author_id" do
    it "finds the questions by an author" do
      questions = Question.find_by_author_id(1)
      expect(questions.all? { |question| question.is_a?(Question) }).to eq(true)
      expect(questions.all? { |question| question.user_id == 1 }).to eq(true)
    end
  end

  describe "followers" do
    it "returns the question's followers" do
      question = Question.find_by_id(1)
      expect(question.followers.all? { |follower| follower.is_a?(User) })
        .to eq(true)
      expect(question.followers[0].id).to eq(3)
    end
  end

  describe "most_liked_questions" do
    it "returns the most liked questions for n=1" do
      questions = Question.most_liked(1)
      expect(questions.length).to eq(1)
      expect(questions.all? { |question| question.is_a?(Question) }).to eq(true)
    end

    it "returns the most liked questions for greater n" do
      questions = Question.most_liked(2)
      expect(questions.length).to eq(2)
      expect(questions.all? { |question| question.is_a?(Question) }).to eq(true)
      expect(questions[0].id).to eq(1)
      expect(questions[1].id).to eq(2)
    end
  end

  describe "saving" do
    describe "saving a new question" do
      it "saves the question to the database" do
        question = Question.new({ 'title' => "How do I look?",
           'body' => "How do I look today, guys?", 'user_id' => 3 })
        expect{question.save}.to change{Question.all.length}.by(1)

      end
    end

    describe "updating an existing question" do
      it "updates the question's information" do
        q = Question.find_by_id(1)
        q.body = "Nevermind, no one responded. :("
        q.save
        updated_q = Question.find_by_id(1)
        updated_body = updated_q.body
        expect(updated_body).to eq("Nevermind, no one responded. :(")
        q.body = "Why is it so hot in here?"
        q.save
      end
    end
  end
end

describe Reply do
  describe "find by question_id" do
    it "finds the replies to a question" do
      replies = Reply.find_by_question_id(1)
      expect(replies.all? { |reply| reply.question_id == 1 }).to eq(true)
      expect(replies.all? { |reply| reply.is_a?(Reply)}).to eq(true)
    end
  end

  describe "find by user_id" do
    it "finds the replies by user id" do
      replies = Reply.find_by_user_id(1)
      expect(replies.all? { |reply| reply.user_id == 1 }).to eq(true)
      expect(replies.all? { |reply| reply.is_a?(Reply)}).to eq(true)
    end
  end

  describe "author" do
    it "finds the author of reply" do
      reply = Reply.find_by_user_id(1)[0]
      expect(reply.author.id).to eq(1)
    end
  end

  describe "question" do
    it "finds the question of the reply" do
      reply = Reply.find_by_question_id(1)[0]
      expect(reply.question.id).to eq(1)
    end
  end

  describe "parent reply" do
    it "find the parent of the reply" do
      reply = Reply.find_by_id(3)
      expect(reply.parent_reply.id).to eq(1)
    end
  end

  describe "child replies" do
    it "find the child replies" do
      reply = Reply.find_by_id(1)
      expect(reply.child_replies[0].id).to eq(3)
    end
  end

end

describe QuestionLike do
  describe "likers for question id" do
    it "should find the likers for the question" do
      likers = QuestionLike.likers_for_question_id(2)
      expect(likers.length).to eq(2)
      expect(likers.all? { |liker| liker.is_a?(User) }).to eq(true)
      expect(likers.map(&:id).sort).to eq([2, 3])
    end
  end

  describe "num likes for question id" do
    it "should return the num likes" do
      likes = QuestionLike.num_likes_for_question_id(1)
      expect(likes).to eq(2)
    end
  end

  describe "liked questions for user id" do
    it "should return the questions liked by the user" do
      questions = QuestionLike.liked_questions_for_user_id(3)
      expect(questions.length).to eq(2)
      expect(questions.map(&:id).sort).to eq([1, 2])
    end
  end

  describe "most_liked_questions" do
    it "returns the most liked questions for n=1" do
      questions = QuestionLike.most_liked_questions(1)
      expect(questions.length).to eq(1)
      expect(questions.all? { |question| question.is_a?(Question) }).to eq(true)
    end

    it "returns the most liked questions for greater n" do
      questions = QuestionLike.most_liked_questions(2)
      expect(questions.length).to eq(2)
      expect(questions.all? { |question| question.is_a?(Question) }).to eq(true)
      expect(questions[0].id).to eq(1)
      expect(questions[1].id).to eq(2)
    end
  end
end