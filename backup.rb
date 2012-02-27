#!/usr/bin/ruby
#require 'rubygems'
require 'logger'
require 'benchmark'
#require 'net/ping'
#require 'net/smtp'

#============================= OPTIONS ==============================#
# == List of VMs.
DOE_POOL      = ['test']
DOMAIN_POOL   = []
SAMBP_XEN     = []
SUNFIRE_XEN   = []

MONTH         = ['test']
WEEK          = ['test']
DAY           = ['test']
# == Log.
LOG_AGE       = 'daily'
# == Email.
FROM	      = 'backup_vm@dp.energy.gov.ua'
TO            = 'dashkevich@dp.energy.gov.ua'

BACKUP_DIR    = '/media/test/'
DIR_MONTH     = 'month/'
DIR_WEEK      = 'week/'
DIR_DAY       = 'day/'

MONTH_DAY     = [12,22]

CONDITION_MONTH = '&&(not MONTH_DAY.include?(t.day))'
CONDITION_WEEK  = '&&(not t.monday?)'
CONDITION_DAY   = '&&(not t.sunday?)&&(not t.saturday?)'
#========================== END OF OPTIONS ==========================#
def backup(frequency,dir,t,condition)
  frequency.each do |vm|
    mkdir = system("mkdir #{BACKUP_DIR}#{dir}#{vm} > /dev/null 2>&1")
    %x[/bin/rm #{BACKUP_DIR}#{dir}#{vm}/*.log] if (File.exist?("#{BACKUP_DIR}#{dir}#{vm}/#{frequency.last}-#{t.month}-#{t.year}.log"))#{condition}
    next if File.exist?("#{BACKUP_DIR}#{dir}#{vm}/#{vm}-#{t.month}-#{t.year}.log")
    @logger = Logger.new("#{BACKUP_DIR}#{dir}#{vm}/#{vm}-#{t.month}-#{t.year}.log", LOG_AGE)
    @logger.info("Started running")
    case true
    when DOE_POOL.include?(vm)
      server = '10.101.97.228'
      pass = "42mBHveOtV"
    when DOMAIN_POOL.include?(vm)
      server = '10.101.97.234'
      pass = "mKHAcuD&KM"
    when SAMBP_XEN.include?(vm)
      server = '10.101.97.112'
      pass = "hsw5}zaL/I"
    when SUNFIRE_XEN.include?(vm)
      server = '10.101.97.121'
      pass = "BvY?7Ea0<Q"
    end
      result = []
      run_time = Benchmark.realtime do
        begin
          @logger.info("Suspend start")
          result << system("xe vm-suspend vm=#{vm} -s #{server} -u root -pw #{pass} >> #{BACKUP_DIR}#{dir}#{vm}/#{vm}-#{t.month}-#{t.year}.log 2>&1")  
          @logger.info("Backup start")
          result << system("xe vm-export vm=#{vm} filename=#{BACKUP_DIR}#{dir}#{vm}/#{vm}-$(date +%d-%m-%Y).backup -s #{server} -u root -pw #{pass} >> #{BACKUP_DIR}#{dir}#{vm}/#{vm}-#{t.month}-#{t.year}.log 2>&1")
          @logger.info("Resume start")
          result << system("xe vm-resume vm=#{vm} -s #{server} -u root -pw #{pass} >> #{BACKUP_DIR}#{dir}#{vm}/#{vm}-#{t.month}-#{t.year}.log 2>&1")
        end
      end
    @logger.info("Removing old backup")
    %x[rm #{BACKUP_DIR}#{dir}#{vm}/`ls -t1r #{BACKUP_DIR}#{dir}#{vm} | head -n 1`] if (result[1] == true) && (mkdir != true)
    @logger.info("Finished running - Backup run time: #{run_time.to_s[0, 5]}")
    send_email_with_log(vm,t,dir) if result.include?(false)   
  end
end

def send_email_with_log(vm,t,dir)
csvnamefile = "#{BACKUP_DIR}#{DIR_DAY}#{vm}/#{vm}-#{t.month}-#{t.year}.log"
binary = File.read(csvnamefile)
encoded = [binary].pack("m")    # base64 econding
puts  value = %x[/usr/sbin/sendmail dashkevich@dp.energy.gov.ua << EOF
subject: Backup VM #{vm}
from: backup-vm
Content-Description: "#{csvnamefile}"
Content-Type: text/csv; name="#{csvnamefile}"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{csvnamefile}"
#{encoded}
EOF]
end

#========================== Main program ==========================#

t=Time.now
if (not t.sunday?)&&(not t.saturday?) then
  backup(DAY,DIR_DAY,t,CONDITION_DAY) 
end

#if (t.sunday?) || (t.saturday?) then
#  backup(WEEK,DIR_WEEK,t,CONDITION_WEEK)
#end

#if MONTH_DAY.include?(t.day) then
#  backup(MONTH,DIR_MONTH,t,CONDITION_MONTH)
#end





#MONTH.each do |vm|
#  t=Time.now
#   %x[/bin/rm #{BACKUP_DIR}*.log] if (File.exist?("#{BACKUP_DIR}#{MONTH.last}-#{t.month}-#{t.year}.log"))&&(not MONTH_DAY.include?(t.day))
#  break if not MONTH_DAY.include?(t.day)
#  break if t.hour == 5
#  next if File.exist?("#{BACKUP_DIR}#{vm}-#{t.month}-#{t.year}.log")
#  @logger = Logger.new("#{BACKUP_DIR}#{vm}-#{t.month}-#{t.year}.log", LOG_AGE)
#  @logger.info("Started running")
#  
#  run_time = Benchmark.realtime do
#     begin
#       backup(vm,'10.101.97.228','42mBHveOtV')  
#     end
#  end
#  @logger.info("Finished running - Execution time: #{run_time.to_s[0, 5]}")
#  send_email_with_log(vm,t)
#  
#end

#WEEK.each do |vm|
#  t=Time.now
#   %x[/bin/rm #{BACKUP_DIR}week/*.log] if (File.exist?("#{BACKUP_DIR}week/#{WEEK.last}-#{t.month}-#{t.year}.log"))&&(not t.monday?)
#  break if not t.monday?
#  break if t.hour == 5
#  next if File.exist?("#{BACKUP_DIR}week/#{vm}-#{t.month}-#{t.year}.log")
#  @logger = Logger.new("#{BACKUP_DIR}week/#{vm}-#{t.month}-#{t.year}.log", LOG_AGE)
#  @logger.info("Started running")
#  
##  run_time = Benchmark.realtime do
##     begin
##       backup(vm,'10.101.97.228','42mBHveOtV',DIR_WEEK)  
##     end
##  end
##  @logger.info("Finished running - Execution time: #{run_time.to_s[0, 5]}")
#  send_email_with_log(vm,t)
#  
#end

#DAY.each do |vm|
#  t=Time.now
#   %x[/bin/rm #{BACKUP_DIR}day/*.log] if (File.exist?("#{BACKUP_DIR}day/#{DAY.last}-#{t.month}-#{t.year}.log"))&&(not t.sunday?)&&(not t.saturday?)
#  break if t.saturday? || t.sunday?
#  break if t.hour == 5
#  next if File.exist?("#{BACKUP_DIR}day/#{vm}-#{t.month}-#{t.year}.log")
#  @logger = Logger.new("#{BACKUP_DIR}day/#{vm}-#{t.month}-#{t.year}.log", LOG_AGE)
#  @logger.info("Started  running")
#  
##  run_time = Benchmark.realtime do
##     begin
##       backup(vm,'10.101.97.228','42mBHveOtV',DIR_DAY)  
##     end
##  end
##  @logger.info("Finished running - Execution time: #{run_time.to_s[0, 5]}")
#  send_email_with_log(vm,t)
#  
#end
