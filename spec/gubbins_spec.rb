require 'spec_helper.rb'

describe DataCollector do
  
  before(:each) do
    @data = instance_double("CollectData")
    allow(@data).to receive(:wan_name) {"eth0"}
    allow(@data).to receive(:lan_name) {"br-lan"}
  end 
  
  it "Should test we have mocked the interface name" do
    expect(@data.wan_name).to eq 'eth0'
  end 
  
  it "Should test we have a mocked the lan interface name" do
    expect(@data.lan_name).to eq 'br-lan'
  end 
  
  it "has a wan_name" do
    expect(@data.wan_name).to match(/eth0/)
    expect(@data).to respond_to(:wan_name)
  end
      
  xit "has a lan_name" do
    expect(@data.lan_name).to match(/br-lan/)
    expect(@data).to respond_to(:lan_name)
  end
  
  it "has a serial" do
    allow(@data).to receive(:serial) {"4535644"}
    expect(@data).to respond_to(:serial)
    expect(@data.serial).to match(/[0-9]/)
  end 
  
  it "has a system_type" do
    allow(@data).to receive(:system_type) {"mips"}
    expect(@data).to respond_to(:system_type)
    expect(@data.system_type).to match(/mips/)
  end
  
  it "has a machine_type" do
    allow(@data).to receive(:machine_type) {"openwrt"}
    expect(@data).to respond_to(:machine_type)
    expect(@data.machine_type).to match(/openwrt/)
  end 
     
    
  it "has a nvs" do
    allow(@data).to receive(:nvs) {"12345"}
    expect(@data).to respond_to(:nvs)
    expect(@data.nvs).to match(/[0-9]/)
  end 
  
  it "has a wvs " do
    allow(@data).to receive(:wvs) {"12345"}
    expect(@data).to respond_to(:wvs)
    expect(@data.wvs).to match(/[0-9]/)
  end 
    
  it "has a sync id " do
    allow(@data).to receive(:sync) {"12345"}
    expect(@data).to respond_to(:sync)
    expect(@data.sync).to match(/[0-9]/)
  end 
  
  it "has a version " do
    allow(@data).to receive(:version) {"1.3"}
    expect(@data).to respond_to(:version)
    expect(@data.version).to match(/[0-9].[0-9]/)
  end 
  
  it "has a api url" do
    allow(@data).to receive(:api_url) {"https://api.polkaspots.com"}
    expect(@data).to respond_to(:api_url)
    expect(@data.api_url).to match(/https:\/\/api.polkaspots.com/)
  end 
  
  it "has a health_url" do
    allow(@data).to receive(:health_url) {"http://health.polkaspots.com/api/v1/health"}
    expect(@data).to respond_to(:health_url)
    expect(@data.health_url).to match(/http:\/\/health.polkaspots.com\/api\/v1\/health/)
  end 
  
  it "has an external server" do
    allow(@data).to receive(:external_server) {"8.8.8.8"}
    expect(@data).to respond_to(:external_server)
    expect(@data.external_server).to match(/8.8.8.8/)
  end 
  
  it "has wan_mac" do
    @data=double
    allow(@data).to receive(:wan_mac).and_return("00:34:34:44:32:3e")
    expect(@data.wan_mac).to match(/00:34:34:44:32:3e/)
  end 
  
  
  xit "has invalid mac address and raise an error" do
    data=double
    allow(data).to receive(:wan_mac).and_raise("invlaid mac")
    data.wan_mac
  end 
  
  it "has firmware version " do
    allow(@data).to receive(:firmware) {"1.3"}
    expect(@data).to respond_to(:firmware)
    expect(@data.firmware).to match(/[0-9].[0-9]/)
  end
    
  it "has active wlan interfaces #interfaces" do
    allow(@data).to receive(:get_active_wlan) {"wlan0 wlan0-1"}
    expect(@data).to respond_to(:get_active_wlan)
    expect(@data.get_active_wlan).to match(//)
  end
  
  it "get the the api_url response code " do
    health_url = "http://www.google.com"
    expect(DataCollector.new).to receive(:check_success_url).with(health_url).and_call_original
    expect(DataCollector.new.check_success_url(health_url)).to eq("300")
  end 
      
  xit "can list the connected wireless clients" do
  
  end 
         
  xit "can list the nearby wireless devices" do
    
  end   
  
  it "can ping to an ip address " do
    ip = "8.8.8.8"
    expect(OfflineResponder.new).to receive(:can_ping_ip).with(ip).and_call_original
    expect(OfflineResponder.new.can_ping_ip(ip)).to eq('fail')
  end 
  
  xit "can log the interface changes to the /etc/status file" do
    
  end 
  
  xit "can zip collected data before post " do
    
  end 
  
  xit "lost the interface ip" do
    
  end 
  
  it "lost the gateway" do
    message = "hello"
    expect(Logger.new).to receive(:log).with(message).and_call_original
  end 
  
  xit "cannot ping to google dns " do
    
  end 
  
    
  
end 
       
