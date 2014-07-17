class ReleasesController < ApplicationController
  def index
    render json: Release.where(artist_id: params[:artist_id])
  end

  def create
    artist = Artist.find params[:artist_id]
    render nothing: true, status: 404 unless artist
    release = artist.releases.create release_params
    if release.valid?
      render json: release
    else
      render nothing: true, status: 500
    end
  end

  def show
    render json: Release.find(params[:id])
  end

  def update
    release = Release.find params[:id]
    render nothing: true, status: 404 unless release
    release.update release_params
    if release.valid?
      render json: release
    else
      render nothing: true, status: 500
    end
  end

  def destroy
    release = Release.find params[:id]
    if release
      release.destroy
      render json: release
    else
      render nothing: true, status: 404
    end
  end

  private
  def release_params
    params.require(:release).permit(:title, :year)
  end
end
