# Parity Testing for Xseed

This directory contains comprehensive parity tests comparing Xseed's output with reference implementations from XS3P and XSDVI tools.

## Test Files

1. **`html_parity_spec.rb`** - HTML documentation parity tests
   - Tests simple fixtures
   - Tests real-world fixtures
   - Compares structural elements, tables, headings, and sections

2. **`svg_parity_spec.rb`** - SVG diagram parity tests
   - Tests simple fixtures
   - Tests real-world fixtures
   - Compares SVG structure, elements, and visual components

3. **`unitsml_parity_spec.rb`** - Comprehensive UnitsML v1.0 parity tests
   - 51 test examples covering all aspects
   - Tests HTML documentation generation
   - Tests SVG diagram generation
   - Tests schema coverage and completeness
   - Tests performance and scalability

## Reference Files

### UnitsML v1.0
- **XSD**: `spec/fixtures/unitsml/unitsml-v1.0.xsd` (58KB, 1343 lines)
- **HTML**: `spec/fixtures/unitsml/index.html` (661KB reference documentation)
- **SVG Diagrams**: `spec/fixtures/unitsml/diagrams/*.svg` (54 diagram files)

## Running Tests

Run all parity tests:
```bash
bundle exec rspec spec/parity/
```

Run specific test suite:
```bash
bundle exec rspec spec/parity/unitsml_parity_spec.rb --format documentation
```

Run with coverage:
```bash
COVERAGE=true bundle exec rspec spec/parity/
```

## Test Results Summary

### UnitsML v1.0 Parity Results

**Overall Score: 90.2% (46/51 tests passing)**

#### Passing Categories (100%)
- ✅ Reference files validation
- ✅ UnitsML-specific content documentation
- ✅ Schema properties section
- ✅ Navigation components
- ✅ Documentation quality metrics
- ✅ Schema coverage analysis
- ✅ Special features handling
- ✅ Performance benchmarks

#### Areas Needing Improvement
- Document title generation (missing schema name)
- Properties table count (49% vs target 70%+)
- Section structure alignment

See [`UNITSML_PARITY_RESULTS.md`](./UNITSML_PARITY_RESULTS.md) for detailed analysis.

## Test Categories

### 1. Reference Files Validation
Tests verify that reference documentation files exist and are valid:
- XSD schema file exists and is parseable
- HTML reference documentation exists
- SVG diagram files exist and are valid XML

### 2. HTML Documentation Parity
Tests compare generated HTML with reference:
- **Document Structure**: HTML5 validity, CSS, JavaScript
- **Navigation**: TOC, sidebars, component links
- **Schema Properties**: Namespace, version, metadata
- **Content Sections**: Properties tables, samples, hierarchies
- **Specific Content**: Schema-specific elements and types
- **Quality Metrics**: Size, element count, type count

### 3. SVG Diagram Parity
Tests compare generated SVG diagrams with reference:
- **Validity**: Well-formed SVG XML
- **Structure**: Visual elements (rect, circle, path, line)
- **Content**: Text labels, relationships, hierarchies
- **Attributes**: Dimensions, viewBox, styling

### 4. Content Completeness
Tests verify comprehensive schema coverage:
- **Schema Parsing**: All elements, types, attributes identified
- **Documentation**: Annotations extracted and included
- **Special Features**: Imports, enumerations, complex content

### 5. Performance & Scalability
Tests ensure efficient processing:
- Generation time for large schemas
- Memory usage for complex schemas
- Handling of extensive enumerations

## Interpreting Results

### Pass Criteria
Tests pass when:
- Generated output is valid (HTML5, XML)
- Structure matches reference within tolerance (typically 20-30%)
- All schema components are documented
- Special features are handled correctly
- Performance meets thresholds

### Pending Tests
Some tests are marked as `pending` when:
- Feature is partially implemented
- Structural differences exist but functionality is present
- Tolerance needs adjustment based on implementation approach

### Tolerance Levels
Different aspects have different tolerance levels:
- **Element counts**: ±20%
- **Table counts**: ±30%
- **Code samples**: Can exceed reference (more is better)
- **Section structure**: May differ if functionality is equivalent

## Adding New Parity Tests

To add parity tests for a new schema:

1. Add reference files to `spec/fixtures/`:
   ```
   spec/fixtures/my_schema/
     ├── my_schema.xsd
     ├── index.html (reference documentation)
     └── diagrams/ (reference SVG files)
   ```

2. Create or extend parity spec:
   ```ruby
   describe "My Schema Parity" do
     let(:xsd_path) { "spec/fixtures/my_schema/my_schema.xsd" }
     let(:reference_html_path) { "spec/fixtures/my_schema/index.html" }

     # Add tests...
   end
   ```

3. Run and document results

## CI Integration

Parity tests are integrated into CI pipeline:
- Run on every pull request
- Track parity percentage over time
- Alert on parity regressions
- Generate coverage reports

## Contributing

When contributing code that affects documentation generation:

1. Run relevant parity tests
2. Document any intentional structural changes
3. Update tolerance levels if needed
4. Add new tests for new features
5. Update results documentation

## License

See main project [LICENSE](../../LICENSE.adoc)