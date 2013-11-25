class AppDelegate
  attr_accessor :status_menu, :manager, :ancs

  def applicationDidFinishLaunching(notification)
    @app_name = NSBundle.mainBundle.infoDictionary['CFBundleDisplayName']

    @status_menu = NSMenu.new

    @status_item = NSStatusBar.systemStatusBar.statusItemWithLength(NSVariableStatusItemLength).init
    @status_item.setMenu(@status_menu)
    @status_item.setHighlightMode(true)
    @status_item.setTitle(@app_name)

    @status_menu.addItem createMenuItem("About #{@app_name}", 'orderFrontStandardAboutPanel:')
    @status_menu.addItem createMenuItem("Custom Action", 'pressAction')
    @status_menu.addItem createMenuItem("Quit", 'terminate:')

    @manager = CBCentralManager.alloc.initWithDelegate self, queue: nil
  end

  def createMenuItem(name, action)
    NSMenuItem.alloc.initWithTitle(name, action: action, keyEquivalent: '')
  end

  def pressAction
    alert = NSAlert.alloc.init
    alert.setMessageText "Action triggered from status bar menu"
    alert.addButtonWithTitle "OK"
    alert.runModal
  end
  
  def subscribeToANCS
    manager.scanForPeripheralsWithServices ["7905F431-B5CE-4E99-A40F-4B1E122D00D0"], options: {CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber.numberWithBool(false)}
  end
  
  def consumeANCS
    manager.connectPeripheral ancs, options:nil
    ancs.delegate = self
    ancs.discoverServices nil
  end
  
  # CBCentralManagerDelegate
  def centralManagerDidUpdateState(manager)
    NSLog "Central manager state: %@", manager.state
    NSLog "haha"
    case manager.state
    when CBCentralManagerStatePoweredOn
      subscribeToANCS
    end
  end

  def centralManager(manager, didDiscoverPeripheral:peripheral, advertisementData:data, RSSI:rssi)
    NSLog "didDiscoverPeripheral %@ %@ %@", peripheral, data, rssi
    @ancs = peripheral
    consumeANCS
  end

  # CBPeripheralDelegate
  def peripheral(peripheral, didDiscoverServices:error)
    NSLog "didDiscoverServices: %@", error

    return if error || !peripheral.services

    peripheral.services.each do |service|
      NSLog "Service found with UUID: %@", service.UUID

      if service.UUID == CBUUID.UUIDWithString("180D")
        NSLog "-> FOUND service heart rate"
        peripheral.discoverCharacteristics nil, forService:service
      end

      if service.UUID == CBUUID.UUIDWithString("180A")
        NSLog "-> FOUND service device information"
        peripheral.discoverCharacteristics nil, forService:service
      end

      if service.UUID == CBUUID.UUIDWithString(CBUUIDGenericAccessProfileString)
        NSLog "-> FOUND service Generic Access Profile"
        peripheral.discoverCharacteristics nil, forService:service
      end
    end
  end

  def peripheral(peripheral, didDiscoverCharacteristicsForService:service, error:error)
    NSLog "didDiscoverCharacteristicsForService: %@ error %@", service, error
  end

  # Invoked upon completion of a "readValueForCharacteristic:" request, or on the reception of a notification
  def peripheral(peripheral, didUpdateValueForCharacteristic:char, error:error)
    NSLog "peripheral: %@ error %@", char, error
  end
end
