class ArtistsController < ApplicationController
  def index
    render json: Artist.all
  end

  def create
    artist = Artist.create artist_params
    if artist.valid?
      render json: artist
    else
      render nothing: true, status: 500
    end
  end

  def show
    render json: Artist.find(params[:id])
  end

  def update
    artist = Artist.find params[:id]
    render nothing: true, status: 404 unless artist
    artist.update artist_params
    if artist.valid?
      render json: artist
    else
      render nothing: true, status: 500
    end
  end

  def destroy
    artist = Artist.find params[:id]
    if artist
      artist.destroy
      render json: artist
    else
      render nothing: true, status: 404
    end
  end

  private
  def artist_params
    params.require(:artist).permit(:name)
  end
end
