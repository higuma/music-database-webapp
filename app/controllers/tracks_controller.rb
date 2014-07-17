class TracksController < ApplicationController
  def index
    render json: Track.where(release_id: params[:release_id])
  end

  def create
    release = Release.find params[:release_id]
    render nothing: true, status: 404 unless release
    track = release.tracks.create track_params
    if track.valid?
      render json: track
    else
      render nothing: true, status: 500
    end
  end

  def show
    render json: Track.find(params[:id])
  end

  def update
    track = Track.find params[:id]
    render nothing: true, status: 404 unless track
    track.update track_params
    if track.valid?
      render json: track
    else
      render nothing: true, status: 500
    end
  end

  def destroy
    track = Track.find params[:id]
    if track
      track.destroy
      render json: track
    else
      render nothing: true, status: 404
    end
  end

  private
  def track_params
    params.require(:track).permit(:number, :title, :minutes, :seconds)
  end
end
