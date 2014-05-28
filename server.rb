require "sinatra"
require "shotgun"
require "pg"
require "pry"

def db_connect
  begin
    connection = PG.connect(dbname: "movies")
    yield(connection)
  ensure
  	connection.close
  end
end

get "/" do
  redirect "/movies"	
end

get "/movies" do
  @movies = db_connect do |conn| conn.exec(
  	"SELECT movies.title, movies.year, movies.rating, genres.name AS genre, 
  	 studios.name AS studio FROM movies JOIN genres ON movies.genre_id = genres.id 
  	 JOIN studios ON movies.studio_id = studios.id ORDER BY movies.title LIMIT 25")
  end
  erb :"/movies/index"
end

get "/movies/:movie_id" do
  @movie_id = params[:movie_id]
  @movie = db_connect do |conn| conn.exec(
  	"SELECT movies.title, movies.rating, movies.year, movies.synopsis, 
  	 studios.name AS studio, genres.name AS genre, actors.name AS actor 
  	 FROM movies JOIN studios ON movies.studio_id = studios.id 
  	 JOIN genres ON movies.genre_id = genres.id JOIN cast_members ON
  	 cast_members.movie_id = movies.id JOIN actors ON actors.id = 
  	 cast_members.actor_id WHERE movies.id = #{@movie_id}")
  end
  erb :"/movies/show"
end

get "/actors" do
  @actors = db_connect do |conn| conn.exec(
  	"SELECT name FROM actors\n
  	 ORDER BY name LIMIT 25")
  end
  erb :"/actors/index"
end

get "/actors/:actor_id" do
  @actor_id = params[:actor_id]
  @actor = db_connect do |conn| conn.exec(
    "SELECT actors.name, movies.title, cast_members.character FROM actors
     JOIN cast_members ON actors.id = cast_members.actor_id
     JOIN movies ON cast_members.movie_id = movies.id
     WHERE actors.id = #{@actor_id} ORDER BY movies.title")
  end
  erb :"/actors/show"
end