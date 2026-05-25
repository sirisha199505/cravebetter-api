class App::Models::Faq < Sequel::Model(:faqs)
  def validate
    super
    validates_presence [:question, :answer]
  end

  def to_pos
    {
      id:       id,
      question: question,
      answer:   answer,
      position: position,
    }
  end
end
