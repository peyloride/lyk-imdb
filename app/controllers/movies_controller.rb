class MoviesController < ApplicationController
  before_action :set_movie, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def index
    @movies = Movie.all
    @movies = @movies.sort_by {|word| word.title.first(1)}
  end

  def show
    @actors = @movie.actors
    @directors = @movie.directors
    update_views(@movie)
  end

  def new
    @movie = Movie.new
    @people = Person.all
    authorize! :new, @movie
  end

  def edit
    @people = Person.all
    authorize! :edit, @movie
  end


  def create
    @movie = current_user.movies.create(movie_params)
    authorize! :create, @movie

    params[:actor_ids].each do |actor_id|
      ActorMovie.create(movie_id: @movie.id, person_id: actor_id.to_i)
    end

    params[:director_ids].each do |director_id|
      DirectorMovie.create(movie_id: @movie.id, person_id: director_id.to_i)
    end

    if @movie.save
      redirect_to @movie, notice: 'Movie Created'
    else
      render :new
    end

  end


  def update

    authorize! :update, @movie
    params[:actor_ids].each do |actor_id|
      actor = ActorMovie.find_by_person_id(actor_id.to_i).try(:person)
      unless @movie.actors.include?(actor)
        ActorMovie.create(movie_id: @movie.id, person_id: actor_id.to_i)
      end
    end

    params[:director_ids].each do |director_id|
      director = DirectorMovie.find_by_person_id(director_id.to_i).try(:person)
      unless @movie.directors.include?(director)
        DirectorMovie.create(movie_id: @movie.id, person_id: director_id.to_i)
      end
    end

    if @movie.update(movie_params)
      redirect_to @movie, notice: "Movie edited successfully."
    else
      render :edit
    end

  end

  def destroy

  end

  def remove_actor
    @movie = Movie.friendly.find(params[:movie_id])
    @person = Person.find(params[:person_id])
    ActorMovie.find_by_movie_id_and_person_id(@movie.id, @person.id).destroy
    @type="actor"
    respond_to do |format|
      format.js {render 'remove'}
    end
  end

  def remove_director
    @movie = Movie.friendly.find(params[:movie_id])
    @person = Person.find(params[:person_id])
    DirectorMovie.find_by_movie_id_and_person_id(@movie.id, @person.id).destroy
    @type="director"
    respond_to do |format|
      format.js {render 'remove'}
    end
  end



  private

  def set_movie
    @movie = Movie.friendly.find(params[:id])
  end

  def movie_params
    params.require(:movie).permit(:title, :director, :story, :image, :trailer)
  end

  def update_views(movie)
    movie.views = movie.views + 1
    movie.save
  end

end
