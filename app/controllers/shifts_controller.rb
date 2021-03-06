class ShiftsController < ApplicationController
  # before_action :set_shift, only: [:show, :edit, :update, :destroy ]

   # GET /shifts/new
  def new
    @shift = Shift.new
  end

  # POST /shifts
    def create
    @shift = Shift.new(shift_params)    
      if @shift.save
         flash[:success] = 'Shift was successfully created.'
         redirect_to @shift          
      else
        render :new      
      end    
  end

  # GET /shifts
  def index
      @shifts = Shift.all.order(:shift_date).select { |s| s.shift_date >= Date.today}
  end

  # GET /shifts/1
  def show
  end

  # GET /shifts/1/edit
  def edit
  end

  def assign_single_shift
    @shift = Shift.find(params[:id])
    @agent_select = Agent.all.order(:last_name).map{|a| [ a.alpha_handle + ": " + a.username,  a.id] }
  end

  def single_shift_assign
    @shift = Shift.find(params[:id])
    @agent = Agent.find(params[:agent_id]) 
    if Shook.exists?(agent_id: @agent_id, date: @shift.shift_date, state: 'assigned')
      flash.now[:danger] = "Agent is already assigned to another shift on #{@shift.shift_date}"
      redirect_to assign_single_shift_path
    else  
      @jhook = Jhook.find_or_create_by(:job_id => @shift.job.id, :agent_id => @agent.id)
      @jhook.update_attributes(state: 'partial')
      @shook =  Shook.find_or_create_by(:agent_id => @agent.id, :shift_id => @shift.id) 
      @shook.update_attributes(date: @shift.shift_date, state: 'assigned' )     
        redirect_to wage_setter_partial_job_jhooks_path(@shift.job)
    end    
  end

  # PATCH/PUT /shifts/1
  def update
  end

 

  def availability_calendar
    @job = Job.find(params[:job_id])
    @shifts_by_date = @job.shifts.all.group_by(&:shift_date)
    @date = params[:date] ? Date.parse(params[:date]) : @job.start_date
  end

  def shift_level_assign
    @shooks = Shook.find(params[:ids])
    @jhook = @shooks.first.jhook
    @job = @jhook.job
    @jhook.update_attributes(state: 'partial_assign')
      @shooks.each do |s|
          if Shook.exists?(agent_id: @agent_id, date: @shift.shift_date, state: 'assigned')
            flash.now[:alert] = "Agent is already assigned to another shift on #{s.date}"
            redirect_to :back
          else  
          s.update_attributes(state: 'assigned')    
          end 
      end    
    redirect_to wage_setter_partial_job_jhooks_path(@job)
  end

  def remove_agents_calendar
    @job = Job.find(params[:job_id])
    @shifts_by_date = @job.shifts.all.group_by(&:shift_date)
    @date = params[:date] ? Date.parse(params[:date]) : @job.start_date
  end

  def shift_level_remove
    @shooks = Shook.find(params[:ids])
    @jhook = @shooks.first.jhook
    @job = @jhook.job
      @shooks.each do |s|
        s.update_attributes(state: 'removed')    
      end
    flash[:success] = 'Shifts were successfully removed'     
    redirect_to jobs_path
  end 

 

  # DELETE /shifts/1
  # DELETE /shifts/1.json
  def destroy
    @shift.destroy
    flash[:success] = 'Shift was successfully destroyed.'
    redirect_to shifts_url    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_shift
      @shift = Shift.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def shift_params
      params.require(:shift).permit(:job_id, :shift_date, :shift_hrs, :available_agents, :agent_id )
    end
end
