import AppKit
import UniformTypeIdentifiers

class SharingManager {
    static let shared = SharingManager()
    // Add a property to store the attributed string being shared
    private var currentAttributedString: NSAttributedString?
    
    private init() {}
    
    func shareText(from textStorage: NSTextStorage, withFontSize fontSize: Double, onSuccess: @escaping () -> Void) {
        // Make a copy of the text storage content
        guard let attributedString = textStorage.copy() as? NSAttributedString,
              !attributedString.string.isEmpty else {
            return
        }
        
        // Store a reference to the attributed string
        self.currentAttributedString = attributedString
        
        // Get plain text from the attributed string
        let plainText = attributedString.string
        
        // Present share sheet with the plain text directly
        let sharingService = NSSharingServicePicker(items: [plainText])
        
        // Get a reference to the button or a view
        if let window = NSApplication.shared.windows.first,
           let contentView = window.contentView {
            
            // Create a reference wrapper to pass to the completion handler
            let clearTextAction = ClearTextAction(action: onSuccess)
            
            sharingService.delegate = SharingServiceDelegate(clearTextAction: clearTextAction)
            
            // Get the view coordinates for the Share button (approximated from the top-right)
            let shareButtonFrame = NSRect(x: contentView.bounds.width - 50,
                                          y: contentView.bounds.height - 50,
                                          width: 20, height: 20)
            
            sharingService.show(relativeTo: shareButtonFrame, of: contentView, preferredEdge: .minY)
        }
    }
}

// Class to hold the clearText action
class ClearTextAction {
    let action: () -> Void
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    func perform() {
        action()
    }
}

// Helper delegate to handle share completion
class SharingServiceDelegate: NSObject, NSSharingServicePickerDelegate {
    private let clearTextAction: ClearTextAction
    
    init(clearTextAction: ClearTextAction) {
        self.clearTextAction = clearTextAction
        super.init()
    }
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        // Set a handler for when sharing is done
        if let service = service {
            service.delegate = self
        } else {
            // If no service was chosen (sharing cancelled), still try to clear
            DispatchQueue.main.async { [weak self] in
                self?.clearTextAction.perform()
            }
        }
    }
}

extension SharingServiceDelegate: NSSharingServiceDelegate {
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        // Sharing completed successfully via delegate method
        clearTextAction.perform()
    }
    
    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        print("^ Sharing failed with error: \(error.localizedDescription)")
        // We could still choose to clear even on failure, depending on requirements
        // clearTextAction.perform()
    }
}

