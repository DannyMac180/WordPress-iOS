import Foundation
import WPMediaPicker
import WordPressShared
import Photos

// Encapsulates all of the interactions required to capture a new Gravatar image, and resize it.
//
class GravatarPickerViewController: UIViewController, WPMediaPickerViewControllerDelegate {
    // MARK: - Public Properties

    @objc var onCompletion: ((UIImage?) -> Void)?

    // MARK: - Private Properties

    fileprivate var mediaPickerViewController: WPNavigationMediaPickerViewController!

    fileprivate lazy var mediaPickerAssetDataSource: WPPHAssetDataSource? = {
        let collectionsFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: nil)
        guard let assetCollection = collectionsFetchResult.firstObject else {
            return nil
        }

        let dataSource = WPPHAssetDataSource()
        dataSource.setSelectedGroup(PHAssetCollectionForWPMediaGroup(collection: assetCollection, mediaType: .image))
        return dataSource
    }()

    // MARK: - View Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildrenViewControllers()
    }


    // MARK: - WPMediaPickerViewControllerDelegate

    func mediaPickerController(_ picker: WPMediaPickerViewController, shouldShow asset: WPMediaAsset) -> Bool {
        return asset.isKind(of: PHAsset.self)
    }

    func mediaPickerController(_ picker: WPMediaPickerViewController, didFinishPicking assets: [WPMediaAsset]) {
        // Export the UIImage Asset
        guard let asset = assets.first as? PHAsset else {
            onCompletion?(nil)
            return
        }

        asset.exportMaximumSizeImage { (image, info) in
            guard let rawGravatar = image else {
                self.onCompletion?(nil)
                return
            }

            // Track
            WPAppAnalytics.track(.gravatarCropped)

            // Proceed Cropping
            let imageCropViewController = self.newImageCropViewController(rawGravatar)
            self.mediaPickerViewController.show(after: imageCropViewController)
        }
    }

    func mediaPickerControllerDidCancel(_ picker: WPMediaPickerViewController) {
        onCompletion?(nil)
    }

    func emptyView(forMediaPickerController picker: WPMediaPickerViewController) -> UIView? {
        return nil
    }

    // MARK: - Private Methods

    // Instantiates a new MediaPickerViewController, and sets it up as a children ViewController.
    //
    fileprivate func setupChildrenViewControllers() {
        let pickerViewController = newMediaPickerViewController()

        pickerViewController.willMove(toParentViewController: self)
        pickerViewController.view.bounds = view.bounds
        view.addSubview(pickerViewController.view)
        addChildViewController(pickerViewController)
        pickerViewController.didMove(toParentViewController: self)

        mediaPickerViewController = pickerViewController
    }

    // Returns a new WPMediaPickerViewController instance.
    //
    fileprivate func newMediaPickerViewController() -> WPNavigationMediaPickerViewController {
        let options = WPMediaPickerOptions()
        options.showMostRecentFirst = true
        options.filter = [.image]
        options.preferFrontCamera = true
        options.allowMultipleSelection = false

        let pickerViewController = WPNavigationMediaPickerViewController(options: options)
        pickerViewController.delegate = self
        pickerViewController.dataSource = mediaPickerAssetDataSource
        pickerViewController.startOnGroupSelector = false
        return pickerViewController
    }

    // Returns a new ImageCropViewController instance.
    //
    fileprivate func newImageCropViewController(_ rawGravatar: UIImage) -> ImageCropViewController {
        let imageCropViewController = ImageCropViewController(image: rawGravatar)
        imageCropViewController.onCompletion = { [weak self] image, _ in
            self?.onCompletion?(image)
            self?.dismiss(animated: true, completion: nil)
        }

        return imageCropViewController
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var childViewControllerForStatusBarStyle: UIViewController? {
        return nil
    }

}
