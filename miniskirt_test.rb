require 'miniskirt'
require 'test/unit'

class MiniskirtTest < Test::Unit::TestCase
  def test_should_define_factories
    factories = Miniskirt.class_variable_get :@@factories
    assert_not_nil factories["user"]
    assert_not_nil factories["post"]
  end

  def test_should_build_object
    user = Factory.build :user
    assert_instance_of User, user
    assert user.new_record?
  end

  def test_should_create_object
    user = Factory.create :user
    assert_instance_of User, user
    assert !user.new_record?
  end

  def test_should_create_object_with_shorthand
    user = Factory :user
    assert !user.new_record?
  end

  def test_should_assign_attributes
    user = Factory.create :user
    assert_not_nil user.login
    assert_not_nil user.email
    assert_not_nil user.password
    assert_not_nil user.password_confirmation
  end

  def test_should_chain_attributes
    user = Factory.create :user
    assert_equal user.password, user.password_confirmation
  end

  def test_should_override_attributes_on_the_fly
    user = Factory.create :user, :login => (login = "janedoe"),
      :email => (email = "janedoe@example.com"),
      :password => (password = "password"),
      :password_confirmation => (password_confirmation = "passwrod")

    assert_equal login, user.login
    assert_equal email, user.email
    assert_equal password, user.password
    assert_equal password_confirmation, user.password_confirmation

    user = Factory.create :user

    assert_not_equal login, user.login
    assert_not_equal email, user.email
    assert_not_equal password, user.password
    assert_not_equal password_confirmation, user.password_confirmation
  end

  def test_should_sequence
    user1 = Factory.create :user
    user2 = Factory.create :user
    assert_equal user1.login.succ, user2.login
  end

  def test_should_interpolate
    user = Factory.create :user
    assert_equal user.email, "#{user.login}@example.com"
  end

  def test_should_allow_aliases_in_define
    user = Factory.build :another_name_for_user
    assert_instance_of User, user
    assert_equal 'test', user.login
  end
end

class Mock
  @@maximum = nil
  def self.maximum(column)
    @@maximum
  end

  def initialize
    yield self
  end

  def save
    @@maximum = @@maximum.to_i + 1 unless @saved
    @saved = true
  end

  def save!
    save
  end

  def new_record?
    !@saved
  end
end

class User < Mock
  attr_accessor :login, :email, :password, :password_confirmation
end

class Post < Mock
  attr_accessor :user
end

Miniskirt.define :user do |f|
  f.login "johndoe%d"
  f.email "%{login}@example.com"
  f.password f.password_confirmation("foobarbaz")
end

Miniskirt.define :user, :as => :another_name_for_user do |f|
  f.login 'test'
end

Miniskirt.define :post do |f|
  f.user { Miniskirt :user }
end
