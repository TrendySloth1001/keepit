import {
  Chev, Grid, Image as ImageIc, Key, Lock, Notes,
  Paperclip, Plus, Search, Settings,
} from "./icons";

/**
 * Static, flat phone canvas. No tilt, no float, no parallax, no hover.
 * Renders a faithful representation of the Keepit Android home screen.
 */
export default function Phone() {
  return (
    <div className="hero__device" aria-label="Keepit app preview">
      <div className="phone">
        <div className="phone__notch" />
        <div className="phone__screen">

          {/* status bar */}
          <div className="sb">
            <div className="sb__time">6:48</div>
            <div className="sb__icons">
              <span className="sb__chip" />
              <span className="sb__chip sb__chip--blue" />
              <span className="sb__sig">●●●●</span>
              <span className="sb__bat">46%</span>
            </div>
          </div>

          {/* header */}
          <div className="app__head">
            <div className="app__title">Nikhil kumawat</div>
            <div className="app__icons">
              <button className="ic-btn" aria-label="Lock"><Lock /></button>
              <button className="ic-btn" aria-label="Settings"><Settings /></button>
            </div>
          </div>

          {/* storage */}
          <div className="cap cap--storage">
            <div className="cap__top">
              <span className="cap__label">Storage</span>
              <span className="cap__val">15.0 MB / 500.0 MB</span>
            </div>
            <div className="bar"><div className="bar__fill" /></div>
          </div>

          {/* search */}
          <div className="cap cap--search">
            <Search className="cap__ic" />
            <span className="cap__ph">Search by title</span>
          </div>

          {/* chips */}
          <div className="chips">
            <button className="chip chip--active"><Grid /> All</button>
            <button className="chip"><span className="chip__dots">•••</span> Passwords</button>
            <button className="chip"><Notes /> Notes</button>
            <button className="chip"><Key /> Keys</button>
            <button className="chip"><ImageIc /> Ima</button>
          </div>

          {/* items */}
          <div className="item">
            <div className="item__ic"><Paperclip /></div>
            <div className="item__body">
              <div className="item__title">5_6298707047256956695.mp4</div>
              <div className="item__meta">File · 14.6 MB · 1d ago</div>
            </div>
            <Chev className="item__chev" />
          </div>

          <div className="item">
            <div className="item__ic"><ImageIc /></div>
            <div className="item__body">
              <div className="item__title">scaled_1000044174.jpg</div>
              <div className="item__meta">Image · 312.4 KB · 2d ago</div>
            </div>
            <Chev className="item__chev" />
          </div>

          <div className="item">
            <div className="item__ic"><Notes /></div>
            <div className="item__body">
              <div className="item__title">my secure note</div>
              <div className="item__meta">Note · 2d ago</div>
            </div>
            <Chev className="item__chev" />
          </div>

          <div className="item">
            <div className="item__ic">
              <span className="item__dots">•••</span>
              <span className="item__line" />
            </div>
            <div className="item__body">
              <div className="item__title">GitHub account</div>
              <div className="item__meta">Password · 2d ago</div>
            </div>
            <Chev className="item__chev" />
          </div>

          <button className="fab" aria-label="Add"><Plus /></button>
          <div className="gesture" />
        </div>
      </div>
    </div>
  );
}
