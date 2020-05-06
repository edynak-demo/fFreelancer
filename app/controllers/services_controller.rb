class ServicesController < ApplicationController

  protect_from_forgery except: [:upload_photo]
  before_action :authenticate_user!, except: [:show]
  before_action :set_service, except: [:new, :create]
  before_action :is_authorised, only: [:edit, :update, :upload_photo, :delete_photo]
  before_action :set_step, only: [:update, :edit]

  def new
    @service = current_user.services.build
    @categories = Category.all
  end

  def create
    @service = current_user.services.build(service_params)

    if @service.save
      @service.pricings.create(Pricing.pricing_types.values.map{ |x| {pricing_type: x} })
      redirect_to edit_service_path(@services), notice: "Save..."
    else
      redirect_to request.referrer, flash: { error: @service.errors.full_messages }
    end
  end

  def edit
    @categories = Category.all
  end

  def update

    if @step == 2
      service_params[:pricings_attributes].each do |index, pricing|
        if @service.has_single_pricing && pricing[:pricing_type] != Pricing.pricing_types.key(0)
          next;
        else
          if pricing[:title].blank? || pricing[:description].blank? || pricing[:delivery_time].blank? || pricing[:price].blank?
            return redirect_to request.referrer, flash: {error: "Invalid pricing"}
          end
        end
      end
    end

    if @step == 3 && service_params[:description].blank?
      return redirect_to request.referrer, flash: {error: "Description cannot be blank"}
    end

    if @step == 4 && @service.photos.blank?
      return redirect_to request.referrer, flash: {error: "You don't have any photos"}
    end

    if @step == 5
      @service.pricings.each do |pricing|
        if @service.has_single_pricing && !pricing.basic?
          next;
        else
          if pricing[:title].blank? || pricing[:description].blank? || pricing[:delivery_time].blank? || pricing[:price].blank?
            return redirect_to edit_service_path(@service, step: 2), flash: {error: "Invalid pricing"}
          end
        end
      end

      if @service.description.blank?
        return redirect_to edit_service_path(@service, step: 3), flash: {error: "Description cannot be blank"}
      elsif @service.photos.blank?
        return redirect_to edit_service_path(@servive, step: 4), flash: {error: "You don't have any photos"}
      end
    end

    if @service.update(service_params)
      flash[:notice] = "Saved..."
    else
      return redirect_to request.referrer, flash: {error: @service.errors.full_messages}
    end

    if @step < 5
      redirect_to edit_service_path(@service, step: @step + 1)
    else
      redirect_to dashboard_path
    end

  end

  def show
  end

  def upload_photo
    @set_service.photos.attach(params[:file])
    render json: { success: true }
  end

  def delete_photo
    @image = ActiveStorage::Attachment.find(params[:photo_id])
    @image.purge
    redirect_to edit_service_path(@service, step: 4)
  end

  private

  def set_step
    @step = params[:step].to_i > 0 ? params[:step].to_i : 1
    if @step > 5
      @step = 5
    end
  end

  def set_service
    @service = Service.find(params[:id])
  end

  def is_authorised
    redirect_to root_path, alert: "You do not have permission" unless current_user.id == @service.user_id
  end

  def service_params
    params.require(:service).permit(:title, :video, :description, :active, :category_id, :has_single_pricing, 
                                pricings_attributes: [:id, :title, :description, :delivery_time, :price, :pricing_type])
  end
end
