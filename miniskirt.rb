require "active_support"
# Factory girl, relaxed.
#
#   Factory.define :user do |f|
#     f.login 'johndoe%d'                               # Sequence.
#     f.email '%{login}@example.com'                    # Interpolate.
#     f.password f.password_confirmation('foobar')      # Chain.
#   end
# 
#   Factory.define :post do |f|
#     f.user { Factory :user }                          # Blocks, if you must.
#   end
# 
#   Factory.define :post, :as => :important_post do |f| # Aliases using :as
#     f.status 'muy importante'
#   end
class Miniskirt < Struct.new(:__klass__)
  undef_method *instance_methods.grep(/^(?!__|object_id)/) # BlankerSlate.
  @@factories = {} and private_class_method :new

  class << self
    def define(name, attrs = {})
      name, klass = attrs.delete(:as), name if attrs.has_key?(:as)
      @@factories[name = name.to_s] = {:class => klass} and yield new(name)
    end

    def build(name, attrs = {})
      (klass, n = (@@factories[name.to_s][:class] || name).to_s) and (m = klass.classify.constantize).new do |rec|
        attrs.symbolize_keys!.reverse_update(@@factories[name.to_s]).each do |k, v|
          rec.send "#{k}=", case v when String # Sequence and interpolate.
            v.sub(/%\d*d/) {|d| d % n ||= m.maximum(:id).to_i + 1} % attrs % n
          when Proc then v.call(rec) else v
          end unless k == :class
        end
      end
    end

    def create(name, attrs = {})
      build(name, attrs).tap { |record| record.save! }
    end
  end

  def method_missing(name, value = nil, &block)
    @@factories[__klass__][name] = block || value
  end
end

def Miniskirt(name, attrs = {})
  Miniskirt.create(name, attrs)
end

Factory = Miniskirt
alias Factory Miniskirt
