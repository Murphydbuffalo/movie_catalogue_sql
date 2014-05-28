require "sinatra"
require "shotgun"
require "pg"

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
  @page = params[:page].to_i || 1
  @page > 1 ? @offset_count = @page - 1 : @offset_count = 0
  sort_criteria = params[:order] || "title"
  sort_criteria == "title" ? order_by = "ORDER BY movies.#{sort_criteria}" : order_by = "ORDER BY movies.#{sort_criteria} DESC"
  query = params[:query] || ""	
  @movies = db_connect do |conn| conn.exec(
  	"SELECT movies.title, movies.year, movies.rating, movies.id, 
  	 genres.name AS genre, studios.name AS studio 
  	 FROM movies 
  	 JOIN genres ON movies.genre_id = genres.id 
  	 JOIN studios ON movies.studio_id = studios.id 
  	 WHERE movies.rating IS NOT NULL AND movies.title ILIKE '%#{query}%'
  	 #{order_by}
  	 LIMIT 20
  	 OFFSET (20 * #{@offset_count})"
  	 )
  end
  erb :"/movies/index"
end

get "/movies/:movie_id" do
  @movie_id = params[:movie_id]
  @movie = db_connect do |conn| conn.exec(
  	"SELECT movies.title, movies.rating, movies.year, movies.synopsis, 
  	 studios.name AS studio, genres.name AS genre, actors.name AS actor, 
  	 actors.id, cast_members.character 
  	 FROM movies 
  	 JOIN studios ON movies.studio_id = studios.id 
  	 JOIN genres ON movies.genre_id = genres.id 
  	 JOIN cast_members ON cast_members.movie_id = movies.id 
  	 JOIN actors ON actors.id = cast_members.actor_id 
  	 WHERE movies.id = #{@movie_id}"
  	 )
  end
  erb :"/movies/show"
end

get "/actors" do
  @page = params[:page].to_i || 1
  @page > 1 ? @offset_count = @page - 1 : @offset_count = 0
  query = params[:query] || ""
  @actors = db_connect do |conn| conn.exec(
  	"SELECT actors.name, actors.id, COUNT(movies.title) 
  	 FROM actors
  	 JOIN cast_members ON actors.id = cast_members.actor_id
     JOIN movies ON movies.id = cast_members.movie_id
  	 WHERE name ILIKE '%#{query}%'
  	 GROUP BY actors.id
  	 ORDER BY name 
  	 LIMIT 20
  	 OFFSET (20 * #{@offset_count})"
  	 )
  end
  erb :"/actors/index"
end

get "/actors/:actor_id" do
  @actor_id = params[:actor_id]
  @actor = db_connect do |conn| conn.exec(
    "SELECT actors.name, movies.title, movies.id, cast_members.character 
     FROM actors 
     JOIN cast_members ON actors.id = cast_members.actor_id
     JOIN movies ON cast_members.movie_id = movies.id
     WHERE actors.id = #{@actor_id} 
     ORDER BY movies.title"
     )
  end
  erb :"/actors/show"
end