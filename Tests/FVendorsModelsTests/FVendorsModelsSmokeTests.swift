import FVendorsModels
import Testing

@Suite("FVendorsModelsSmokeTests")
struct FVendorsModelsSmokeTests {
    @Test("Module compiles")
    func moduleCompiles() {
        #expect(Bool(true))
    }
}
