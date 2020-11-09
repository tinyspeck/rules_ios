import XCTest
@testable import TestImports_App

class SwiftTests : XCTestCase {
  func testPasses() {
      _ = EmptyStruct()
      XCTAssertTrue(true)
  }

  func testPasses2() {
      let empty = EmptyClass()
      empty.embraceNothingness()

      XCTAssertTrue(true)
  }
}
