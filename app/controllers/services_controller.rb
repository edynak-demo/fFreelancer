class ServicesController < ApplicationController

  before_action :authenticate_user!, except: [:show]
  before_action :set_service, except: [:new, :create]
  before_action :is_authorised, only: [:edit, :update]

  def new
    @service = current_user.services.build
    @categories = Category.all
  end

  def create
    @service = current_user.services.build(service_params)

    if @service.save
      @service.pricings.create(Pricing.pricing_types.values.map{ |x| {pricing_type: x} })
      redirect_to edit_service_path(@service), notice: "Save..."
    else
      redirect_to request.referrer, flash: { error: @service.errors.full_messages }
    end
  end

  def edit
    @categories = Category.all
    @step = params[:step].to_i
  end

  def update
  end

  def show
  end

  private

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
