require 'spec_helper.rb'

describe CollectData do
  
  before(:each) do
    @data = instance_double("CollectData")
    allow(@data).to receive(:wan_name) {"eth0"}
    allow(@data).to receive(:lan_name) {"br-lan"}
  end 
  
  it "Should test we have mocked the interface name" do
    expect(@data.wan_name).to eq 'eth0'
  end 
  
  it "Should test we have a mocked the wan interface name" do
    expect(@data.lan_name).to eq 'br-lan'
  end 
  
  it "has a wan_name" do
    expect(@data.wan_name).to match(/eth0/)
    expect(@data).to respond_to(:wan_name)
  end
      
  it "has a lan_name" do
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
  
  it "has a wan_ip" do
    allow(@data).to receive(:get_wan_ip).and_return("10.0.1.1")
    expect(@data).to receive(:get_wan_ip).with(any_args())
    expect(@data.wan_ip).to match(/10.0.1.1/)
  end 
  
  it "has wan_mac" do
    wan_mac = double("wan_mac")
    expect(wan_mac).to receive(:wan_mac) {eth0}
    expect(wan_mac).to respond_to(:wan_mac)
    expect(@data.wan_mac).to match(//)
  end 
  
  
 
end 
       
