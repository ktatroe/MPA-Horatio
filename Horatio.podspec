Pod::Spec.new do |s|
  s.name = 'Horatio'
  s.version = '0.3'

  s.ios.deployment_target = '9.0'

  s.license = 'MIT'
  s.summary = 'Horatio is a library of patterns, protocols, and classes typical for the "skeleton" of a modern app.'  
  s.homepage = 'https://github.com/ktatroe/MPA-Horatio'
  s.author = { 'Kevin Tatroe' => 'support@mudpotapps.com' }
  s.source = { :git => 'https://github.com/ktatroe/MPA-Horatio.git', :tag => s.version.to_s }

  s.description = 'Operations queue with conditions, observers, and improved error handling ' \
				  '(based on Apple’s \"Advanced NSOperations\" sample code). ' \
				  'HTTP requests for standard REST services. ' \
				  'An injection container. ' \
				  'A feature availability system for global or per-subject behaviors.'  

  s.requires_arc = true
  
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Horatio/Horatio/**/*.{h,swift}'
    core.exclude_files = 'Horatio/Horatio/Classes/Operations/{Calendar,CKContainer,Cloud,Health,Location,Passbook,Photos,Remote,UIUser,User}*.swift'
  end

  s.subspec 'EventKit' do |event|
    event.source_files = 'Horatio/Horatio/Classes/Operations/{Calendar}*.swift'
	event.framework = 'EventKit'
    event.dependency 'Horatio/Core'
  end

  s.subspec 'CloudKit' do |cloud|
    cloud.source_files = 'Horatio/Horatio/Classes/Operations/{CKContainer,Cloud}*.swift'
    cloud.framework = 'CloudKit'
    cloud.dependency 'Horatio/Core'
  end

  s.subspec 'HealthKit' do |health|
    health.source_files = 'Horatio/Horatio/Classes/Operations/{Health}*.swift'
	health.framework = 'HealthKit'
    health.dependency 'Horatio/Core'
  end

  s.subspec 'CoreLocation' do |loc|
    loc.source_files = 'Horatio/Horatio/Classes/Operations/{Location}*.swift'
	loc.framework = 'CoreLocation'
    loc.dependency 'Horatio/Core'
  end

  s.subspec 'PassKit' do |pass|
    pass.source_files = 'Horatio/Horatio/Classes/Operations/{Passbook}*.swift'
	pass.framework = 'PassKit'
    pass.dependency 'Horatio/Core'
  end

  s.subspec 'Photos' do |photos|
    photos.source_files = 'Horatio/Horatio/Classes/Operations/{Photos}*.swift'
	photos.framework = 'Photos'
    photos.dependency 'Horatio/Core'
  end

  s.subspec 'Notifications' do |notif|
    notif.source_files = 'Horatio/Horatio/Classes/Operations/{Remote,UIUser,User}*.swift'
	notif.framework = 'UserNotifications'
    notif.dependency 'Horatio/Core'
  end

end
