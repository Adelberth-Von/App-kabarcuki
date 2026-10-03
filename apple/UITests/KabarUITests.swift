import XCTest
final class KabarUITests: XCTestCase {
    private func tapVisible(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<8 { if element.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(element.waitForExistence(timeout:5));element.tap()
    }
    func testSenderFlowAndEditableButtons() throws {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["-KabarQAClean"]; app.launch()
        let opened=app.buttons["sender-setup"].waitForExistence(timeout:40)
        let screenshot=XCTAttachment(screenshot:app.screenshot());screenshot.name="Kabar initial screen";screenshot.lifetime = .keepAlways;add(screenshot)
        XCTAssertTrue(opened,app.debugDescription);app.buttons["sender-setup"].tap()
        // The status controls are below the fold on iPhone; verify navigation before scrolling.
        XCTAssertTrue(app.tabBars.buttons["Beranda"].waitForExistence(timeout:15),app.debugDescription)
        // Pause delivery to verify the persistent offline queue through actual taps.
        app.tabBars.buttons["Pengaturan"].tap();tapVisible(app.buttons["Jeda koneksi"],app:app);app.tabBars.buttons["Beranda"].tap()
        app.swipeUp();app.buttons["home"].tap();app.buttons["Batal"].tap();app.tabBars.buttons["Riwayat"].tap();XCTAssertTrue(app.staticTexts["Belum ada kabar. Status baru akan muncul di sini."].exists);app.tabBars.buttons["Beranda"].tap();app.swipeUp()
        app.buttons["home"].tap();app.buttons["confirm-status"].tap();app.buttons["meal"].tap();app.buttons["confirm-status"].tap();app.buttons["outside"].tap();app.buttons["confirm-status"].tap()
        app.swipeDown();XCTAssertTrue(app.staticTexts["Keluar"].firstMatch.waitForExistence(timeout:5))
        app.tabBars.buttons["Riwayat"].tap();XCTAssertTrue(app.staticTexts["Di kost"].exists)
        app.tabBars.buttons["Pengaturan"].tap();for _ in 0..<4 { app.swipeDown() };tapVisible(app.buttons["Edit nama, tombol & jam makan"],app:app)
        let fields=app.textFields
        XCTAssertTrue(fields["Kost"].waitForExistence(timeout:5))
        let home=fields["Kost"];home.tap();home.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:4)+"Rumah")
        app.navigationBars.buttons["Simpan"].tap();XCTAssertTrue(app.buttons["Ya, simpan"].waitForExistence(timeout:5));app.buttons["Ya, simpan"].tap();app.tabBars.buttons["Beranda"].tap();app.swipeUp()
        XCTAssertTrue(app.buttons["home"].waitForExistence(timeout:5));app.buttons["home"].tap();app.buttons["confirm-status"].tap()
        app.tabBars.buttons["Riwayat"].tap();XCTAssertTrue(app.staticTexts["Di rumah"].waitForExistence(timeout:5))
        app.terminate();app.launchArguments=[];app.launch();app.tabBars.buttons["Riwayat"].tap()
        XCTAssertTrue(app.staticTexts["Di rumah"].waitForExistence(timeout:5))
        let final=XCTAttachment(screenshot:app.screenshot());final.name="Kabar edited history";final.lifetime = .keepAlways;add(final)
        app.tabBars.buttons["Pengaturan"].tap();for _ in 0..<5 { app.swipeDown() }
        tapVisible(app.buttons["theme-relationship"],app:app)
        tapVisible(app.segmentedControls["appearance-mode"].buttons["Gelap"],app:app)
        XCTAssertTrue(app.buttons["theme-relationship"].isSelected)
        let appearance=XCTAttachment(screenshot:app.screenshot());appearance.name="Relationship dark settings";appearance.lifetime = .keepAlways;add(appearance)
        app.tabBars.buttons["Beranda"].tap();for _ in 0..<3 { app.swipeDown() }
        XCTAssertTrue(app.staticTexts["local-clock"].exists)
        let dark=XCTAttachment(screenshot:app.screenshot());dark.name="Relationship dark home";dark.lifetime = .keepAlways;add(dark)
        app.terminate();app.launch()
        app.tabBars.buttons["Pengaturan"].tap()
        XCTAssertTrue(app.buttons["theme-relationship"].isSelected)
        XCTAssertTrue(app.segmentedControls["appearance-mode"].buttons["Gelap"].isSelected)
        tapVisible(app.segmentedControls["appearance-mode"].buttons["Terang"],app:app)
        app.tabBars.buttons["Beranda"].tap();for _ in 0..<3 { app.swipeDown() }
        let light=XCTAttachment(screenshot:app.screenshot());light.name="Relationship light home";light.lifetime = .keepAlways;add(light)
    }
}
