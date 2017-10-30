class WorksController < ApplicationController
  # We should always be able to tell what category
  # of work we're dealing with
  before_action :category_from_work, except: [:root, :index, :new, :create]

  def root
    # @login_user = User.find_by(id: session[:user_id])
    @albums = Work.best_albums
    @books = Work.best_books
    @movies = Work.best_movies
    @best_work = Work.order(vote_count: :desc).first
  end

  def index
    @works_by_category = Work.to_category_hash
  end

  def new
    @work = Work.new
  end

  def create
    @work = Work.new(media_params)
    @media_category = @work.category
    @work.user_id = session[:user_id]

    if @work.save
      flash[:status] = :success
      flash[:result_text] = "Successfully created #{@media_category.singularize} #{@work.id}"
      redirect_to work_path(@work)
    else
      flash[:status] = :failure
      flash[:result_text] = "Could not create #{@media_category.singularize}"
      flash[:messages] = @work.errors.messages
      render :new, status: :bad_request
    end
  end

  def show
    @votes = @work.votes.order(created_at: :desc)
  end

  #only the user who created the work can edit
  def edit
    unless @work.can_edit_or_delete_work?(session[:user_id])
      redirect_to work_path(@work.id)
      flash[:result_text] = "Only the person that added the work can edit or delete it"
    end
  end

  #only the user who created the work can update
  def update
    # puts "BEFORE LOGIC****"
    # ap params
    # puts "@work.user: #{@work.user}"
    # puts "params[:id]: #{params[:id]}"
    # puts "BEFORE LOGIC****"
    unless @work.can_edit_or_delete_work?(session[:user_id])
      # puts "unless****************"
      # puts @work.can_edit_or_delete_work?(params[:user_id])
      redirect_to work_path(@work.id)
      flash[:result_text] = "Only the person that added the work can edit or delete it"
      # puts "unless****************"
    else
      @work.update_attributes(media_params)
      if @work.save
        puts "SAVED!"
        flash[:status] = :success
        flash[:result_text] = "Successfully updated #{@media_category.singularize} #{@work.id}"
        redirect_to work_path(@work.id)
      else
        puts "@work not saved****************"
        ap @work
        puts "@work not saved****************"
        flash.now[:status] = :failure
        flash.now[:result_text] = "Could not update #{@media_category.singularize}"
        flash.now[:messages] = @work.errors.messages
        render :edit, status: :not_found
      end
    end
  end

  def destroy
    if @work.can_edit_or_delete_work?(session[:user_id])
      @work.destroy
      flash[:status] = :success
      flash[:result_text] = "Successfully destroyed #{@media_category.singularize} #{@work.title}"
      redirect_to root_path
    else
      flash.now[:status] = :failure
      flash.now[:result_text] = "Could not delete the work #{@work.title}"
      redirect_to work_path(@work.id)
    end
  end

  def upvote
    if @work.can_edit_or_delete_work?(session[:user_id])
      flash[:result_text] = "You cannot vote on your own works"
    else
      if @login_user
        vote = Vote.new(user: @login_user, work: @work)
        if vote.save
          flash[:status] = :success
          flash[:result_text] = "Successfully upvoted!"
          status = :found
        else
          flash[:result_text] = "Could not upvote"
          flash[:messages] = vote.errors.messages
          status = :conflict
        end
      else
        flash[:result_text] = "You must log in to do that"
        status = :unauthorized
      end
    end

    # Refresh the page to show either the updated vote count
    # or the error message
    redirect_back fallback_location: work_path(@work), status: status
  end

private
  def media_params
    params.require(:work).permit(:title, :category, :creator, :description, :publication_year)
  end

  def category_from_work
    @work = Work.find_by(id: params[:id])
    render_404 unless @work
    @media_category = @work.category.downcase.pluralize
  end
end
