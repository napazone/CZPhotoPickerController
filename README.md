CZPhotoPickerController
=======================

CZPhotoPickerController simplifies picking, taking, or using the last photo.

It presents a `UIActionSheet` with the appropriate options for the device, taking into
account photo library permissions and whether or not the device has a camera, and then
presents a `UIImagePickerController` (when picking an existing photo or taking a new one)
or returns the last photo taken.

It supports the iPhone and iPad.

Usage:

    __weak typeof(self) weakSelf = self;

    photoPicker = [[CZPhotoPickerController alloc] initWithPresentingViewController:self withCompletionBlock:^(UIImagePickerController *imagePickerController, NSDictionary *imageInfoDict) {

      if (imagePickerController.allowsEditing) {
        weakSelf.imageView.image = imageInfoDict[UIImagePickerControllerEditedImage];
      }
      else {
        weakSelf.imageView.image = imageInfoDict[UIImagePickerControllerOriginalImage];
      }

      if (weakSelf.modalViewController) {
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
      }

    }];

    photoPicker.allowsEditing = YES;

    [photoPicker showFromBarButtonItem:btn];

If `allowsEditing` is `YES`, the user will be asked to resize the chosen image. Otherwise a preview is shown.

Screenshots
-----------

![Action sheet](http://carezone.github.com/CZPhotoPickerController/images/picker1.PNG)

![Allows editing](http://carezone.github.com/CZPhotoPickerController/images/picker2.PNG)


Credits
-------

CZPhotoPickerController was created by [Brian Cooke](https://github.com/bricooke) and [Peyman Oreizy](https://github.com/peymano) in the development of [CareZone Mobile for iOS](https://itunes.apple.com/us/app/carezone-mobile/id552197945).

Contact
-------

Brian Cooke @bricooke

Peyman Oreizy @peymano

License
-------

CZPhotoPickerController is available under the Apache 2.0 license. See the LICENSE file for more info.
