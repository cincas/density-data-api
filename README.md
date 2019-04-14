# Density Data API

## API abstraction

Created `APIClient`, `Datasource` and `DataUnit` for abstracting logic away from `DensityDataAPI`, which benefits unit testing and futrue refactoring



## Performance

- Used parallel tasks to retrieve data from `DensityDataAPI`.

- A full list of snapshots for data set is pre-built after retriving data from API, which helped improving rendering performance a little bit.

- `Throttler` is created for quick changing `UISlider`, which was a major performance issue.

- Ideally, could improve how `GridView` renders grid content.

- A `sample.mov` is included with project file, it demonstrates average performance look like in a 2018 MacBook Pro. Performance in a 2014 MacBook Air was bit slow.

  

### Unit tests

All non-UI classes are tested, including:

- `Atomic`
- `DataProcessor`
- `DataConfiguration`
- `Throttler`
- `DataGridViewModel`



## GIT

GIT history is included in zip file, hopefully it can helps showing how this assignment was progressed.



## TODO

- Improve rendering performance, so building full snapshots is no longer required
- UI Tests
- Build a better UI
