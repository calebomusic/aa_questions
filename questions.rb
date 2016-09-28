require 'byebug'
require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class ModelBase
  TABLEZ = { :User => 'users', :Question => 'questions', :Reply => 'replies'}

  def self.all
    instances = QuestionsDatabase.instance.execute("SELECT * FROM #{TABLEZ[self.select_table]}")
    instances.map { |instance| self.new(instance) }
  end

  def self.select_table
    self.to_s.to_sym
  end

  def self.find_by_id(id)
    match = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{TABLEZ[self.select_table]}
      WHERE
        id = ?
      SQL
    self.new(match.first)
  end


  def save
    variables_without_id = instance_variables_without_id
    variables_without_at = instance_variables_without_at_and_id
    variables_with_id = self.instance_variables

    if @id.nil?
      QuestionsDatabase.instance.execute(<<-SQL, *variables_without_id)
        INSERT INTO
          #{TABLEZ[self.class.select_table]} (#{variables_without_at_and_id.to_s[1...-1]})
        VALUES
          (#{make_question_marks})
        SQL
        @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, *variables_with_id)
        UPDATE
          #{TABLEZ[self.class.select_table]}
        SET
          #{set_questions_for_update(variables_without_at)}
        WHERE
          id = ?
        SQL
    end

    self
  end

  def set_questions_for_update(variables)
    variables.map { |var| var.to_s + ' = ?'}.join(' AND ')
  end

  def make_question_marks
    marks = []
    variables_without_id.length.times do
      marks << "?"
    end

    marks.join(", ")
  end

  def instance_variables_without_id
    result = self.instance_variables
    result.reject! { |var| var == :@id}
    result
  end

  def instance_variables_without_at_and_id
    debugger
    variables = instance_variables_without_id
    variables.map!(&:to_s)
    variables.map! {|variable| variable.gsub(/@/, "")}
    variables.map(&:to_sym)
  end

end
class User < ModelBase
  attr_accessor :fname, :lname

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  # def self.all
  #   users = QuestionsDatabase.instance.execute("SELECT * FROM users")
  #   users.map { |user| User.new(user)}
  # end

  # def self.find_by_id(id)
  #   user = QuestionsDatabase.instance.execute(<<-SQL, id)
  #       SELECT
  #         *
  #       FROM
  #         users
  #       WHERE
  #         id = ?
  #     SQL
  #   return nil if user.empty?
  #   User.new(user.first)
  # end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ?, lname = ?
      SQL
    return nil if user.empty?
    User.new(user.first)
  end

  # def save
  #   if @id.nil?
  #   QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
  #     INSERT INTO
  #       users (fname, lname)
  #     VALUES
  #       (?, ? )
  #     SQL
  #     @id = QuestionsDatabase.instance.last_insert_row_id
  #   else
  #     QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
  #     UPDATE
  #       users
  #     SET
  #       fname = ?, lname = ?
  #     WHERE
  #       id = ?
  #   SQL
  #
  #   end
  #   self
  # end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_author_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        COUNT(question_likes.user_id) / CAST(COUNT(DISTINCT(questions.id)) AS float) AS average_karma
      FROM
        questions
        LEFT OUTER JOIN
          question_likes
        ON
          questions.id = question_likes.question_id
      WHERE
        questions.author_id = ?
    SQL
  end
end

class Question < ModelBase
  attr_accessor :author_id, :title, :body

  def initialize(options)
    @id = options['id']
    @author_id = options['author_id']
    @title = options['title']
    @body = options['body']
  end

  # def self.all
  #   questions = QuestionsDatabase.instance.execute("SELECT * FROM questions")
  #   questions.map { |question| Question.new(question) }
  # end

  # def self.find_by_id(id)
  #   question = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       questions
  #     WHERE
  #       id = ?
  #     SQL
  #   return nil if question.empty?
  #   Question.new(question.first)
  # end

  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
      SQL
    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

#   def save
#     if @id.nil?
#       QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
#       INSERT INTO
#         questions (title, body, author_id)
#       VALUES
#         ( ?, ?, ?)
#       SQL
#       @id = QuestionsDatabase.instance.last_insert_row_id
#     else
#       QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id, @id)
#       UPDATE
#         questions
#       SET
#         title = ?, body = ?, author_id = ?
#       WHERE
#         id = ?
#       SQL
#     end
#     self
#   end
end


class QuestionFollow
  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        id, fname, lname
      FROM
        users
      JOIN
        question_follows
      ON
        question_follows.user_id = users.id
      WHERE
        question_follows.question_id = ?
    SQL
    return nil if users.empty?
    users.map {|user| User.new(user)}
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      JOIN
        question_follows
      ON
        question_follows.question_id = questions.id
      WHERE
        user_id = ?
    SQL
    return nil if questions.empty?
    questions.map {|question| Question.new(question)}
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        *
      FROM
        questions
      JOIN
        question_follows
      ON
        question_follows.question_id = questions.id
      GROUP BY
        id
      ORDER BY
        COUNT(question_follows.user_id) DESC
      LIMIT
        ?
    SQL
  end
end

class Reply < ModelBase
  attr_accessor :title, :body, :question_id, :parent_id, :id, :author_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @author_id = options['author_id']
  end

  # def self.all
  #   replies = QuestionsDatabase.instance.execute("SELECT * FROM replies")
  #   replies.map {|reply| Reply.new(reply)}
  # end
  #
  # def self.find_by_id(id)
  #   reply = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT
  #       *
  #     FROM
  #       replies
  #     WHERE
  #       id = ?
  #     SQL
  #   return nil if reply.empty?
  #   Reply.new(reply.first)
  # end

  def self.find_by_author_id(author_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
      SQL
    return nil if replies.empty?
    replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
      SQL
    return nil if replies.empty?
    replies.map {|reply| Reply.new(reply) }
  end

  def author
    User.find_by_id(@author_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_id)
  end

  def child_replies
    result = Reply.find_by_question_id(@question_id)
    result.delete_if {|reply| reply.id == self.id }
    result
  end

#   def save
#     if @id.nil?
#       QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @question_id, @parent_id, @author_id)
#       INSERT INTO
#         replies(title, body, question_id, parent_id, author_id)
#       VALUES
#         ( ?, ?, ?, ?, ?)
#       SQL
#       @id = QuestionsDatabase.instance.last_insert_row_id
#     else
#       QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @question_id, @parent_id, @author_id, @id)
#       UPDATE
#         replies
#       SET
#         title = ?, body = ?, question_id = ?, parent_id = ?, author_id = ?
#       WHERE
#         id = ?
#       SQL
#     end
#     self
#   end
end

class QuestionLike
  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT DISTINCT
        *
      FROM
        users
        JOIN
          question_likes
        ON
          question_likes.user_id = users.id
      WHERE
        question_id = ?
      SQL
    return nil if users.empty?
    users.map { |user| User.new(user) }
  end

  def self.num_likes_for_question_id(question_id)
    QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT COUNT(user_id) AS num_likes
    FROM users
    JOIN question_likes
    ON question_likes.user_id = users.id
    WHERE question_id = ?
    SQL

  end

  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM questions
      JOIN question_likes
      ON question_likes.question_id = questions.id
      WHERE user_id = ?
    SQL
    return nil if questions.empty?
    questions.map {|question| Question.new(question)}
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT *
      FROM questions
      JOIN question_likes
      ON questions.id = question_likes.question_id
      GROUP BY id
      ORDER BY COUNT(id) DESC
      LIMIT ?
    SQL
    return nil if questions.empty?
    questions.map {|question| Question.new(question)}
  end
end
