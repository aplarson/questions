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
end

describe Follower do
  it "should return a single user by id" do
    expect(Question.find_by_id(1).is_a?(Question)).to eq(true)
    expect(Question.find_by_id(1).id).to eq(1)
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
      expect(questions.all? { |question| question.id == 1 }).to eq(true)
    end
  end
end