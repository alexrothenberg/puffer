class Admin::NewsController < Puffer::Base

  setup do
    group :news
  end

  index do
    field :title
    field :body
  end

  form do
    field :title
    field :body
  end

end
