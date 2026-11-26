import CarPlay

final class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController,
                                  to window: CPWindow) {
        print("[CarPlay] didConnect — scene bağlandı, entitlement OK")
        PlayerEngine.shared.attachCarPlay(interfaceController: interfaceController)
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController,
                                  from window: CPWindow) {
        print("[CarPlay] didDisconnect")
        PlayerEngine.shared.detachCarPlay()
    }
}
