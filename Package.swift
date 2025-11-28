// swift-tools-version:5.2
  import PackageDescription

  let packageName = "LocalPictureSaver"
  
  let package = Package(
      name: packageName,
      platforms: [
          .iOS(.v13)
      ],
      products: [
          .library(name: packageName, targets: [packageName])
      ],
      targets: [
          .target(name: packageName, path: packageName)
          
      ]
  )