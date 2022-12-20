FROM ruby:slim
RUN gem install sqlite3
COPY main.rb /main.rb
CMD ["ruby", "main.rb"]